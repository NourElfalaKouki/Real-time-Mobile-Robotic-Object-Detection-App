# code backend
import rclpy
from rclpy.node import Node
import serial
import pynmea2
import io
import cv2
import torch
import pyrealsense2 as rs
import numpy as np
import threading
import math
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, db
import time
import uuid
from ultralytics import YOLO
 
class FirebaseHandler:
    def __init__(self, robot_id="go2_robot_001"):
        self.robot_id = robot_id
        self.ref = db.reference(f'robot_detections/{robot_id}')
 
    def send_detection_data(self, robot_lat, robot_lon, robot_attitude, detections_list):
        timestamp = datetime.now().isoformat() + 'Z'
        firebase_detections = []
        for detection in detections_list:
            obj_name, confidence, distance, bearing, obj_lat, obj_lon = detection
            firebase_detections.append({
                'object_detected': obj_name,
                'distance': float(distance),
                'object_gps': {
                    'latitude': float(obj_lat),
                    'longitude': float(obj_lon)
                },
                'timestamp': timestamp,
                'detection_id': str(uuid.uuid4())
            })
        data = {
            'robot_id': self.robot_id,
            'timestamp': timestamp,
            'robot_position': {
                'latitude': float(robot_lat),
                'longitude': float(robot_lon),
                'attitude': float(robot_attitude)
            },
            'detections': firebase_detections,
            'status': 'active'
        }
        self.ref.set(data)
 
    def send_heartbeat(self, robot_lat, robot_lon, robot_attitude):
        timestamp = datetime.now().isoformat() + 'Z'
        heartbeat_data = {
            'robot_id': self.robot_id,
            'timestamp': timestamp,
            'robot_position': {
                'latitude': float(robot_lat),
                'longitude': float(robot_lon),
                'attitude': float(robot_attitude)
            },
            'status': 'active',
            'last_heartbeat': timestamp
        }
        heartbeat_ref = db.reference(f'robot_status/{self.robot_id}')
        heartbeat_ref.set(heartbeat_data)
 
class DepthCamera:
    def __init__(self):
        self.pipeline = rs.pipeline()
        self.config = rs.config()
        self.config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)
        self.config.enable_stream(rs.stream.depth, 640, 480, rs.format.z16, 30)
        self.align = rs.align(rs.stream.color)
        self.profile = self.pipeline.start(self.config)
        color_profile = self.profile.get_stream(rs.stream.color)
        self.intr = color_profile.as_video_stream_profile().get_intrinsics()
        self.f_x, self.c_x = self.intr.fx, self.intr.ppx
 
    def get_frame(self):
        frames = self.pipeline.wait_for_frames()
        aligned_frames = self.align.process(frames)
        color_frame = aligned_frames.get_color_frame()
        depth_frame = aligned_frames.get_depth_frame()
        if not color_frame or not depth_frame:
            return None, None
        return (np.asanyarray(color_frame.get_data()), depth_frame)
 
    def release(self):
        self.pipeline.stop()
 
def calculate_gps_coordinates(lat_1, lon_1, distance, bearing):
    METERS_PER_LAT_DEGREE = 111139
    bearing_rad = math.radians(bearing)
    lat_1_rad = math.radians(lat_1)
    delta_lat = distance * math.cos(bearing_rad)
    delta_lon = distance * math.sin(bearing_rad)
    delta_lat_deg = delta_lat / METERS_PER_LAT_DEGREE
    delta_lon_deg = delta_lon / (METERS_PER_LAT_DEGREE * math.cos(lat_1_rad))
    lat_2 = lat_1 + delta_lat_deg
    lon_2 = lon_1 + delta_lon_deg
    return lat_2, lon_2
 
def calculate_bearing(x_c, f_x, c_x, theta_r):
    alpha = math.degrees(math.atan2(x_c - c_x, f_x))
    bearing = (theta_r + alpha) % 360
    return bearing
 
def compute_average_depth(x1, y1, x2, y2, depth_frame):
    u, v = (x1 + x2) // 2, (y1 + y2) // 2
    distance = depth_frame.get_distance(u, v)
    return distance if distance > 0 else None
 
class Go2DetectionNode(Node):
    def __init__(self):
        super().__init__('go2_detection_node')
        self.gps_lat = None
        self.gps_lon = None
        self.gps_alt = None
        self.gps_timestamp = None
        self.gps_lock = threading.Lock()
        self.firebase_handler = FirebaseHandler()
        self.dc = DepthCamera()
        self.yolo_model = YOLO('/path/to/weights.pt')
        self.theta_r = 0
        self.frame = None
        self.depth_frame = None
        self.detections = []
        self.lock = threading.Lock()
        threading.Thread(target=self.gps_read_loop, daemon=True).start()
        threading.Thread(target=self.read_frame_loop, daemon=True).start()
        threading.Thread(target=self.detect_objects_loop, daemon=True).start()
        self.create_timer(1.0, self.send_data)
        self.create_timer(5.0, self.send_heartbeat)
 
    def gps_read_loop(self):
        ser = serial.Serial('COM3', 9600, timeout=1)
        sio = io.TextIOWrapper(io.BufferedRWPair(ser, ser))
        while rclpy.ok():
            try:
                line = sio.readline()
                msg = pynmea2.parse(line)
                with self.gps_lock:
                    self.gps_lat = msg.latitude
                    self.gps_lon = msg.longitude
                    self.gps_alt = getattr(msg, 'altitude', None)
                    self.gps_timestamp = msg.timestamp
            except Exception:
                continue
 
    def read_frame_loop(self):
        while rclpy.ok():
            f, d = self.dc.get_frame()
            if f is not None:
                with self.lock:
                    self.frame = f
                    self.depth_frame = d
 
    def detect_objects_loop(self):
        while rclpy.ok():
            with self.lock:
                if self.frame is None:
                    continue
                results = self.yolo_model(self.frame)
            temp_detections = []
            for result in results:
                for box in result.boxes:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    obj_name = self.yolo_model.names[int(box.cls)]
                    confidence = float(box.conf)
                    avg_depth = compute_average_depth(x1, y1, x2, y2, self.depth_frame)
                    if avg_depth is not None:
                        u = (x1 + x2) // 2
                        bearing = calculate_bearing(u, self.dc.f_x, self.dc.c_x, self.theta_r)
                        with self.gps_lock:
                            if self.gps_lat is None:
                                continue
                            lat_obj, lon_obj = calculate_gps_coordinates(self.gps_lat, self.gps_lon, avg_depth, bearing)
                        temp_detections.append((obj_name, confidence, avg_depth, bearing, lat_obj, lon_obj))
            with self.lock:
                self.detections = temp_detections
 
    def send_data(self):
        with self.gps_lock:
            if self.gps_lat is None:
                return
            lat_r = self.gps_lat
            lon_r = self.gps_lon
        with self.lock:
            dets = self.detections.copy()
        if dets:
            self.firebase_handler.send_detection_data(lat_r, lon_r, self.theta_r, dets)
 
    def send_heartbeat(self):
        with self.gps_lock:
            if self.gps_lat is None:
                return
            self.firebase_handler.send_heartbeat(self.gps_lat, self.gps_lon, self.theta_r)
 
# Firebase Configuration
def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        # Replace with your Firebase service account key path
        cred = credentials.Certificate(r"C:\Users\ELITE\Desktop\ObjectRecognitionAndDistanceEstimation\go2-ai-detection-firebase-adminsdk-fbsvc-c8de4bac28.json")
        firebase_admin.initialize_app(cred, {
            'databaseURL': 'https://go2-ai-detection-default-rtdb.firebaseio.com/'
        })
        print("Firebase initialized successfully")
        return True
    except Exception as e:
        print(f"Firebase initialization error: {e}")
        return False
 
def main():
    rclpy.init()
    initialize_firebase()
    node = Go2DetectionNode()
    rclpy.spin(node)
    node.dc.release()
    cv2.destroyAllWindows()
    node.destroy_node()
    rclpy.shutdown()
 
if __name__ == '__main__':
    main()