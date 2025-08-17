# main.py (improved)

import cv2
import torch
from object_detection import detect_objects, use_cuda_yolo
# from depth_estimation import estimate_depth  # only needed when no depth camera; see below
from object_geojson import create_geojson
from depth_camera import DepthCamera, compute_average_depth, calculate_bearing, calculate_gps_coordinates
from web_camera import WebcamCamera
from socket_server import SocketServer
from datetime import datetime, timezone
import threading
import requests
from gps_reader import GPSReader
from deep_sort_realtime.deepsort_tracker import DeepSort

# -----------------------------
# Tracker
# -----------------------------
tracker = DeepSort(max_age=30, n_init=3, max_cosine_distance=0.3)

# -----------------------------
# State
# -----------------------------
prev_tracked_objects = []
gpsavailable = False
gpsconnected = False


def objects_changed(prev, current):
    """
    Compare *sets* of (id, label, lat, lon, altitude) to be order-insensitive
    and detect any change in identity, label, or position.
    """
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
    """
    Try RealSense first; if unavailable, fall back to regular webcam.
    Returns (camera_instance, is_depth_camera: bool).
    """
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
    """
    Prefer GPS when available/connected, else fallback to IP-based geolocation.
    """
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
    """
    Build a colorized depth visualization and resize to match (width, height)
    of the target frame for vertical stacking (vconcat requires same width).
    """
    h, w = target_size
    depth_norm = cv2.normalize(depth_map_like, None, 0, 255, cv2.NORM_MINMAX)
    depth_uint8 = depth_norm.astype('uint8')
    depth_colored = cv2.applyColorMap(depth_uint8, cv2.COLORMAP_INFERNO)
    # Resize depth visualization to same width as the frame (for vconcat)
    depth_colored_resized = cv2.resize(depth_colored, (w, w * depth_colored.shape[0] // depth_colored.shape[1]))
    # After proportional resize, enforce exact width & height match if needed
    depth_colored_resized = cv2.resize(depth_colored_resized, (w, h))
    return depth_colored_resized


def main():
    global prev_tracked_objects, gpsavailable, gpsconnected

    # -----------------------------
    # Socket server
    # -----------------------------
    socket_server = SocketServer(host='192.168.0.7', port=5000)
    threading.Thread(target=socket_server.run, daemon=True).start()

    # -----------------------------
    # GPS
    # -----------------------------
    gps = None
    try:
        gps = GPSReader(port='/dev/ttyUSB0', baudrate=9600)
        threading.Thread(target=gps.start, daemon=True).start()
    except Exception as e:
        print("[GPS] Failed to start GPS reader:", e)

    # these MUST be updated as globals (bugfix)
    gpsavailable = gps.is_available() if gps else False
    gpsconnected = gps.is_connected() if gps else False
    if not gpsavailable or not gpsconnected:
        print("[GPS] GPS not available or not connected.")
        if gps:
            gps.stop()
        gps = None

    # -----------------------------
    # CUDA / GPU Info
    # -----------------------------
    print("CUDA available:", torch.cuda.is_available())
    if torch.cuda.is_available():
        try:
            print("GPU:", torch.cuda.get_device_name(0))
        except Exception:
            pass

    # -----------------------------
    # Camera
    # -----------------------------
    camera, is_depth = initialize_camera()

    # If you want monocular depth when no depth camera, import here lazily
    estimate_depth = None
    if not is_depth:
        from depth_estimation import estimate_depth  # lazy import (only when needed)

    try:
        while True:
            CURRENT_LAT, CURRENT_LON, CURRENT_ALT = get_current_location(gps)
            # Use UTC with proper Z suffix
            Timestamp = datetime.now(timezone.utc).isoformat()

            frame, depth_data = camera.get_frame()
            if frame is None:
                print("[ERROR] No frame received from camera.")
                continue

            # -----------------------------
            # Object detection
            # -----------------------------
            detections = detect_objects(frame)

            # DeepSORT expects (tlbr), confidence, class_name per detection
            deep_sort_inputs = []
            for det in detections:
                x1, y1, x2, y2 = det["bbox"]
                conf = float(det.get("confidence", 0.0))
                cls_name = det.get("label", "object")
                deep_sort_inputs.append(((x1, y1, x2, y2), conf, cls_name))

            tracks = tracker.update_tracks(deep_sort_inputs, frame=frame)

            # -----------------------------
            # Depth visualization data
            # -----------------------------
            if is_depth and depth_data is not None:
                # depth_data should already be a metric map from the RealSense
                depth_for_vis = depth_data
                depth_map_for_sampling = depth_data
            else:
                # Monocular depth estimation (MiDaS or similar)
                # estimate_depth returns (disp, raw_depth_like) per your module
                _, depth_map = estimate_depth(frame, (0, 0))
                depth_for_vis = depth_map
                depth_map_for_sampling = depth_map

            # -----------------------------
            # Build objects list (start with robot)
            # -----------------------------
            objects = [{
                "id": "robot",
                "label": "robot",
                "lat": CURRENT_LAT,
                "lon": CURRENT_LON,
                "altitude": CURRENT_ALT,
                "timestamp": Timestamp
            }]

            # -----------------------------
            # Tracks → objects with geo projection
            # -----------------------------
            h, w = frame.shape[:2]
            dh, dw = depth_map_for_sampling.shape[:2] if depth_map_for_sampling is not None else (h, w)

            for track in tracks:
                if not track.is_confirmed():
                    continue

                track_id = track.track_id
                l, t, r, b = track.to_ltrb()
                # Clip to image bounds
                l = max(0, min(int(l), w - 1))
                r = max(0, min(int(r), w - 1))
                t = max(0, min(int(t), h - 1))
                b = max(0, min(int(b), h - 1))
                if r <= l or b <= t:
                    continue

                center_x = (l + r) // 2
                center_y = (t + b) // 2

                # Some DeepSort builds return None for class, guard it
                label = track.get_det_class() or "object"

                # Map center to depth map coordinates if sizes differ
                sx = int(center_x * (dw / float(w)))
                sy = int(center_y * (dh / float(h)))
                sx = max(0, min(sx, dw - 1))
                sy = max(0, min(sy, dh - 1))

                depth_val = float(depth_map_for_sampling[sy, sx]) if depth_map_for_sampling is not None else 0.0

                if CURRENT_LAT is not None and CURRENT_LON is not None and is_depth and depth_data is not None:
                    # Average metric distance inside the box from RealSense map
                    distance = float(compute_average_depth(l, t, r, b, depth_data))
                    # Horizontal bearing from principal point (approx)
                    # Note: uses camera intrinsics from your DepthCamera
                    bearing = float(calculate_bearing(center_x, camera.f_x, camera.c_x, 0))
                    lat, lon, alt = calculate_gps_coordinates(CURRENT_LAT, CURRENT_LON, distance, bearing)
                    distance_text = f"Distance: {distance:.2f}m"
                else:
                    # Fallback: no metric triangulation → just display depth value
                    lat, lon, alt = CURRENT_LAT, CURRENT_LON, CURRENT_ALT
                    distance_text = f"Depth: {depth_val:.2f}"

                # Draw with a small margin and clipping
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

            # -----------------------------
            # Emit GeoJSON only on change
            # -----------------------------
            if objects_changed(prev_tracked_objects, objects):
                geojson_data = create_geojson(objects)
                print("Sending GeoJSON data to socket server...", geojson_data, "\n")
                socket_server.send_frame_data(geojson_data)
                prev_tracked_objects = objects
            else:
                print("No change in tracked objects — skipping send.")

            # -----------------------------
            # Visualization (stack frame + depth vertically)
            # vconcat requires same width → we force-match width
            # -----------------------------
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
