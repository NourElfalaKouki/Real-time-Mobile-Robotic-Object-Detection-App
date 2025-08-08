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

def objects_changed(prev_objects, current_objects):
    if len(prev_objects) != len(current_objects):
        return True
    for obj1, obj2 in zip(prev_objects, current_objects):
        if obj1.get("id") != obj2.get("id"):
            return True
        if obj1.get("label") != obj2.get("label"):
            return True
        if round(obj1.get("lat", 6)) != round(obj2.get("lat", 6)):
            return True
        if round(obj1.get("lon", 6)) != round(obj2.get("lon", 6)):
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

def get_current_location_with_offset(base_lat, base_lon, lat_offset, lon_offset):
    return base_lat + lat_offset, base_lon + lon_offset

def get_current_location():
    try:
        response = requests.get("http://ip-api.com/json/")
        data = response.json()
        if data["status"] == "success":
            return data["lat"], data["lon"]
        else:
            print("IP-API error:", data)
    except Exception as e:
        print("Exception in IP-API:", e)

    return None, None



def main():
    socket_server = SocketServer(host='192.168.0.7', port=5000)
    threading.Thread(target=socket_server.run, daemon=True).start()

    print("CUDA available:", torch.cuda.is_available())
    if torch.cuda.is_available():
        print("GPU:", torch.cuda.get_device_name(0))

    camera, is_depth = initialize_camera()

    # Get base location once
    base_lat, base_lon = get_current_location()
    if base_lat is None or base_lon is None:
        print("[ERROR] Could not retrieve base location. Exiting.")
        return

    # Simulated movement offsets
    delta_lat = 0.00001  # about ~1.1 meters north/south
    delta_lon = 0.00001  # about ~0.9 meters east/west at Tunisia's latitude
    frame_count = 0

    prev_detected_objects = []

    while True:
        objects = []
        frame_count += 1

        # Simulate movement
        current_lat, current_lon = get_current_location_with_offset(
            base_lat, base_lon,
            lat_offset=delta_lat * frame_count,
            lon_offset=delta_lon * frame_count
        )

        Timestamp = datetime.now().isoformat()

        # Add robot itself as an object
        objects.append({
            "label": "robot",
            "lat": current_lat,
            "lon": current_lon,
            "timestamp": Timestamp
        })

        frame, depth_data = camera.get_frame()
        if frame is None:
            print("[ERROR] No frame received from camera.")
            break

        detections = detect_objects(frame)
        _, depth_map = estimate_depth(frame, (0, 0))
        depth_norm = cv2.normalize(depth_map, None, 0, 255, cv2.NORM_MINMAX)
        depth_uint8 = depth_norm.astype('uint8')
        depth_colored = cv2.applyColorMap(depth_uint8, cv2.COLORMAP_INFERNO)

        for det in detections:
            center = det["center"]
            label = det["label"]
            confidence = det["confidence"]
            x1, y1, x2, y2 = det["bbox"]

            depth_val, _ = estimate_depth(frame, center)

            if is_depth:
                distance = compute_average_depth(x1, y1, x2, y2, depth_data)
                bearing = calculate_bearing(center[0], camera.f_x, camera.c_x, 0)
                lat, lon = calculate_gps_coordinates(current_lat, current_lon, distance, bearing)
            else:
                lat, lon = current_lat, current_lon

            # Draw box and text
            cv2.rectangle(frame, (x1+30, y1+30), (x2 -30, y2-30), (0, 255, 0), 2)
            cv2.putText(frame, label, (x1+30, y1+25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 0), 2)
            cv2.putText(frame, f"Conf: {confidence:.2f}", (x1+30, y1+15), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 255), 2)
            if not is_depth:
                cv2.putText(frame, f"depth: {depth_val:.2f}", (x1+30, y2 - 25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)
            else:
                cv2.putText(frame,f"Distance: {distance:.2f}", (x1 + 30, y2 - 25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)

            objects.append({
                "id": det["id"],
                "label": label,
                "lat": lat,
                "lon": lon,
                "timestamp": Timestamp,
            })

        # Compare only non-robot objects for change detection
        current_detected_objects = [obj for obj in objects if obj.get("label") != "robot"]

        if objects_changed(prev_detected_objects, current_detected_objects):
            geojson_data = create_geojson(objects)
            print("Sending GeoJSON data to socket server...", geojson_data, "\n")
            socket_server.send_frame_data(geojson_data)
            prev_detected_objects = current_detected_objects
        else:
            print("No change in detected objects — skipping GeoJSON send.\n")

        height = frame.shape[0]
        depth_colored_resized = cv2.resize(depth_colored, (int(depth_colored.shape[1] * height / depth_colored.shape[0]), height))
        combined = cv2.vconcat([frame, depth_colored_resized])
        cv2.imshow("Camera & Depth Map", combined)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    camera.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    use_cuda_yolo()
    main()
