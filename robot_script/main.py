import cv2
import torch
import geocoder
from object_detection import detect_objects,use_cuda_yolo
from depth_estimation import estimate_depth
from object_geojson import create_geojson
from depth_camera import DepthCamera, compute_average_depth, calculate_bearing, calculate_gps_coordinates
from web_camera import WebcamCamera
from socket_server import SocketServer
from datetime import datetime
import threading
import requests
from gps_reader import GPSReader
import serial
from deep_sort_realtime.deepsort_tracker import DeepSort
import math


tracker = DeepSort(max_age=30, n_init=3, max_cosine_distance=0.3)

prev_tracked_objects = []

def objects_changed(prev, current, pos_tolerance=1.0):
    if len(prev) != len(current):
        return True
    for obj1, obj2 in zip(prev, current):
        if obj1["id"] != obj2["id"]:
            return True
        if obj1["label"] != obj2["label"]:
            return True


    return False


def initialize_camera():
    try:
        camera = DepthCamera()
        print("RealSense camera initialized.")
        is_depth = True
    except Exception as e:
        print(f"RealSense not available: {e}")
        camera = WebcamCamera()
        print("Falling back to regular webcam.")
        is_depth = False
    return camera, is_depth



def get_current_location(gps, timeout=5):
    if gps is not None and gps.is_available() and gps.is_connected():
        print("[Location] Using GPS data...")
        lat, lon, alt = gps.get_location(timeout=timeout)
        return lat, lon, alt

    try:
        response = requests.get("http://ip-api.com/json/")
        data = response.json()
        if data["status"] == "success":
            print("[Location] Using IP-based geolocation...")
            return data["lat"], data["lon"], 10.0
        else:
            print("[IP-API Error]", data)
    except Exception as e:
        print("[Location Error]", e)

    return None, None, None


def main():
    global prev_tracked_objects

    socket_server = SocketServer(host='192.168.0.7', port=5000)
    threading.Thread(target=socket_server.run, daemon=True).start()

    gps = GPSReader(port='/dev/ttyUSB0', baudrate=9600)
    threading.Thread(target=gps.start, daemon=True).start()

    print("CUDA available:", torch.cuda.is_available())
    if torch.cuda.is_available():
        print("GPU:", torch.cuda.get_device_name(0))

    camera, is_depth = initialize_camera()

    while True:
        CURRENT_LAT, CURRENT_LON, CURRENT_ALT = get_current_location(gps)
        Timestamp = datetime.now().isoformat() + "Z"

        frame, depth_data = camera.get_frame()
        if frame is None:
            print("[ERROR] No frame received from camera.")
            break

        detections = detect_objects(frame)

        deep_sort_inputs = []
        for det in detections:
            x1, y1, x2, y2 = det["bbox"]
            conf = det["confidence"]
            cls_name = det["label"]
            deep_sort_inputs.append(((x1, y1, x2, y2), conf, cls_name))

        tracks = tracker.update_tracks(deep_sort_inputs, frame=frame)

        _, depth_map = estimate_depth(frame, (0, 0))
        depth_norm = cv2.normalize(depth_map, None, 0, 255, cv2.NORM_MINMAX)
        depth_uint8 = depth_norm.astype('uint8')
        depth_colored = cv2.applyColorMap(depth_uint8, cv2.COLORMAP_INFERNO)

        objects = [{
            "id": "robot", 
            "label": "robot",
            "lat": CURRENT_LAT,
            "lon": CURRENT_LON,
            "timestamp": Timestamp
        }]
        h, w = depth_map.shape[:2]
        for track in tracks:
            if not track.is_confirmed():
                continue

            track_id = track.track_id
            l, t, r, b = track.to_ltrb()
            center_x = int((l + r) / 2)
            center_y = int((t + b) / 2)
            center_x = max(0, min(center_x, w - 1))
            center_y = max(0, min(center_y, h - 1))
            
            label = track.get_det_class()
            depth_val = depth_map[center_y, center_x]

            if CURRENT_LAT is not None and CURRENT_LON is not None and is_depth:
                distance = compute_average_depth(int(l), int(t), int(r), int(b), depth_data)
                bearing = calculate_bearing(center_x, camera.f_x, camera.c_x, 0)
                lat, lon, alt = calculate_gps_coordinates(CURRENT_LAT, CURRENT_LON, distance, bearing)
            else:
                lat, lon, alt = CURRENT_LAT, CURRENT_LON, CURRENT_ALT

            cv2.rectangle(frame, (int(l)+30, int(t)+30), (int(r)-30, int(b)-30), (0, 255, 0), 2)
            cv2.putText(frame, label, (int(l)+30, int(t)+25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 0), 2)
            if not is_depth:
                cv2.putText(frame, f"depth: {depth_val:.2f}", (int(l)+30, int(b)-25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)
            else:
                cv2.putText(frame, f"Distance: {distance:.2f}", (int(l)+30, int(b)-25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)

            objects.append({
                "id": track_id,
                "label": label,
                "lat": lat,
                "lon": lon,
                "timestamp": Timestamp,
                "altitude": alt,
            })

        if objects_changed(prev_tracked_objects, objects):
            geojson_data = create_geojson(objects)
            print("Sending GeoJSON data to socket server...", geojson_data, "\n")
            socket_server.send_frame_data(geojson_data)
            prev_tracked_objects = objects
        else:
            print("No change in tracked objects — skipping send.")

        height = frame.shape[0]
        depth_colored_resized = cv2.resize(
            depth_colored, (int(depth_colored.shape[1] * height / depth_colored.shape[0]), height)
        )
        combined = cv2.vconcat([frame, depth_colored_resized])
        cv2.imshow("Camera & Depth Map", combined)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    camera.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    use_cuda_yolo()
    main()
