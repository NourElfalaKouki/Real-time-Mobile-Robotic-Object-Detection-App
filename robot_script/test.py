import cv2
import torch
import random
import math
from object_detection import detect_objects, use_cuda_yolo
from object_geojson import create_geojson
from depth_camera import DepthCamera, compute_average_depth, calculate_bearing, calculate_gps_coordinates
from web_camera import WebcamCamera
from socket_server import SocketServer
from datetime import datetime, timezone
import threading
import requests
from gps_reader import GPSReader
from deep_sort_realtime.deepsort_tracker import DeepSort
from dotenv import load_dotenv
import os

load_dotenv()

HOST = os.getenv('HOST', '192.168.0.7')
PORT = int(os.getenv('PORT', 5000))
GPS_PORT = os.getenv('GPS_PORT', '/dev/ttyUSB0')
GPS_BAUDRATE = int(os.getenv('GPS_BAUDRATE', 9600))

tracker = DeepSort(max_age=30, n_init=3, max_cosine_distance=0.3)

prev_tracked_objects = []
gpsavailable = False
gpsconnected = False


def objects_changed(prev, current):
    def to_keyset(objs):
        keys = set()
        for o in objs:
            keys.add((
                str(o.get("id")),
                str(o.get("label")),
                round(o.get("lat") or 0.0, 6),
                round(o.get("lon") or 0.0, 6),
                round((o.get("altitude") or 0.0), 1),
            ))
        return keys
    return to_keyset(prev) != to_keyset(current)


def initialize_camera():
    try:
        camera = DepthCamera()
        print("[Camera] RealSense camera initialized.")
        is_depth = True
    except Exception as e:
        print(f"[Camera] RealSense not available: {e}")
        camera = WebcamCamera()
        print("[Camera] Falling back to regular webcam.")
        is_depth = False
    return camera, is_depth


def get_current_location(gps, timeout=5):
    if gps is not None and gpsavailable and gpsconnected:
        try:
            print("[Location] Using GPS data...")
            lat, lon, alt = gps.get_location(timeout=timeout)
            return lat, lon, alt
        except Exception as e:
            print("[GPS Error]", e)
    try:
        response = requests.get("http://ip-api.com/json/", timeout=3)
        data = response.json()
        if data.get("status") == "success":
            print("[Location] Using IP-based geolocation...")
            return data.get("lat"), data.get("lon"), 10.0
        else:
            print("[IP-API Error]", data)
    except Exception as e:
        print("[Location Error]", e)
    return None, None, None


def build_depth_visual(depth_map_like, target_size):
    h, w = target_size
    depth_norm = cv2.normalize(depth_map_like, None, 0, 255, cv2.NORM_MINMAX)
    depth_uint8 = depth_norm.astype('uint8')
    depth_colored = cv2.applyColorMap(depth_uint8, cv2.COLORMAP_INFERNO)
    depth_colored_resized = cv2.resize(depth_colored, (w, w * depth_colored.shape[0] // depth_colored.shape[1]))
    depth_colored_resized = cv2.resize(depth_colored_resized, (w, h))
    return depth_colored_resized


def add_random_offset(lat, lon, max_offset_meters=50):
    max_offset_deg = max_offset_meters / 111000.0
    angle = random.uniform(0, 2 * math.pi)
    distance = random.uniform(0, max_offset_deg)
    lat_offset = distance * math.cos(angle)
    lon_offset = distance * math.sin(angle)
    return lat + lat_offset, lon + lon_offset


def main():
    global prev_tracked_objects, gpsavailable, gpsconnected

    socket_server = SocketServer(host=HOST, port=PORT)
    threading.Thread(target=socket_server.run, daemon=True).start()

    gps = None
    try:
        gps = GPSReader(port=GPS_PORT, baudrate=GPS_BAUDRATE)
        threading.Thread(target=gps.start, daemon=True).start()
    except Exception as e:
        print("[GPS] Failed to start GPS reader:", e)

    gpsavailable = gps.is_available() if gps else False
    gpsconnected = gps.is_connected() if gps else False
    if not gpsavailable or not gpsconnected:
        print("[GPS] GPS not available or not connected.")
        if gps:
            gps.stop()
        gps = None

    print("CUDA available:", torch.cuda.is_available())
    if torch.cuda.is_available():
        try:
            print("GPU:", torch.cuda.get_device_name(0))
        except Exception:
            pass

    camera, is_depth = initialize_camera()

    estimate_depth = None
    if not is_depth:
        from depth_estimation import estimate_depth

    skip_count = 0
    MAX_SKIPS = 5

    try:
        while True:
            CURRENT_LAT, CURRENT_LON, CURRENT_ALT = get_current_location(gps)
            Timestamp = datetime.now(timezone.utc).isoformat()

            frame, depth_data = camera.get_frame()
            if frame is None:
                print("[ERROR] No frame received from camera.")
                continue

            detections = detect_objects(frame)

            deep_sort_inputs = []
            for det in detections:
                x1, y1, x2, y2 = det["bbox"]
                conf = float(det.get("confidence", 0.0))
                cls_name = det.get("label", "object")
                deep_sort_inputs.append(((x1, y1, x2, y2), conf, cls_name))

            tracks = tracker.update_tracks(deep_sort_inputs, frame=frame)

            if is_depth and depth_data is not None:
                depth_for_vis = depth_data
                depth_map_for_sampling = depth_data
            else:
                _, depth_map = estimate_depth(frame, (0, 0))
                depth_for_vis = depth_map
                depth_map_for_sampling = depth_map

            objects = [{
                "id": "robot",
                "label": "robot",
                "lat": CURRENT_LAT,
                "lon": CURRENT_LON,
                "altitude": CURRENT_ALT,
                "timestamp": Timestamp
            }]

            h, w = frame.shape[:2]
            dh, dw = depth_map_for_sampling.shape[:2] if depth_map_for_sampling is not None else (h, w)

            for track in tracks:
                if not track.is_confirmed():
                    continue

                track_id = track.track_id
                l, t, r, b = track.to_ltrb()
                l = max(0, min(int(l), w - 1))
                r = max(0, min(int(r), w - 1))
                t = max(0, min(int(t), h - 1))
                b = max(0, min(int(b), h - 1))
                if r <= l or b <= t:
                    continue

                center_x = (l + r) // 2
                center_y = (t + b) // 2

                label = track.get_det_class() or "object"

                sx = int(center_x * (dw / float(w)))
                sy = int(center_y * (dh / float(h)))
                sx = max(0, min(sx, dw - 1))
                sy = max(0, min(sy, dh - 1))

                depth_val = float(depth_map_for_sampling[sy, sx]) if depth_map_for_sampling is not None else 0.0

                if CURRENT_LAT is not None and CURRENT_LON is not None and is_depth and depth_data is not None:
                    distance = float(compute_average_depth(l, t, r, b, depth_data))
                    bearing = float(calculate_bearing(center_x, camera.f_x, camera.c_x, 0))
                    lat, lon, alt = calculate_gps_coordinates(CURRENT_LAT, CURRENT_LON, distance, bearing)
                    distance_text = f"Distance: {distance:.2f}m"
                else:
                    lat, lon, alt = CURRENT_LAT, CURRENT_LON, CURRENT_ALT
                    distance_text = f"Depth: {depth_val:.2f}"

                if lat is not None and lon is not None:
                    lat, lon = add_random_offset(lat, lon, max_offset_meters=10)

                pad = 4
                cv2.rectangle(frame, (max(0, l + pad), max(0, t + pad)),
                              (min(w - 1, r - pad), min(h - 1, b - pad)), (0, 255, 0), 2)
                cv2.putText(frame, str(label), (l, max(0, t - 8)), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 0), 2)
                cv2.putText(frame, distance_text, (l, min(h - 5, b + 18)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)

                objects.append({
                    "id": track_id,
                    "label": str(label),
                    "lat": float(lat) if lat is not None else None,
                    "lon": float(lon) if lon is not None else None,
                    "altitude": float(alt) if alt is not None else None,
                    "timestamp": Timestamp,
                })

            geojson_data = create_geojson(objects)
            print("Sending GeoJSON data to socket server...", geojson_data, "\n")
            socket_server.send_frame_data(geojson_data)
            prev_tracked_objects = objects

            depth_vis = build_depth_visual(depth_for_vis, (frame.shape[0], frame.shape[1]))
            combined = cv2.vconcat([frame, depth_vis])
            cv2.imshow("Camera (top) + Depth (bottom)", combined)

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    finally:
        try:
            camera.release()
        except Exception:
            pass
        try:
            if gps:
                gps.stop()
        except Exception:
            pass
        cv2.destroyAllWindows()


if __name__ == "__main__":
    use_cuda_yolo()
    main()

