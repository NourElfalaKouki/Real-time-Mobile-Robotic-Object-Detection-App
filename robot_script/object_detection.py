from ultralytics import YOLO
import torch

model = YOLO("yolov8n.pt")

def use_cuda_yolo():
    if torch.cuda.is_available():
        print("Using GPU for inference")
        model.to('cuda')

def detect_objects(frame):
    results = model.track(source=frame,verbose=False, conf=0.5)[0]
    detections = []

    for box in results.boxes:
        label = model.names[int(box.cls)]
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        obj_id = int(box.id.item()) if box.id is not None else -1

        detections.append({
            "id": obj_id,
            "label": label,
            "confidence": float(box.conf[0]),
            "bbox": (x1, y1, x2, y2),
            "center": ((x1 + x2) // 2, (y1 + y2) // 2)
        })

    return detections
