import pyrealsense2 as rs
import numpy as np
 
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
 

def load_midas():
    model_type = "DPT_Large"
    midas = torch.hub.load("intel-isl/MiDaS", model_type)
    midas.eval()
    transform = Compose([
        Resize(512),
        ToTensor(),
        Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    return midas, transform
 
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
    if depth_frame is None:
        return None
    u, v = (x1 + x2) // 2, (y1 + y2) // 2
    distance = depth_frame.get_distance(u, v)
    return distance if distance > 0 else None