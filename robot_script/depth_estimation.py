import torch
import cv2
import numpy as np
from transformers import DPTImageProcessor, DPTForDepthEstimation
from PIL import Image
from transformers import DPTImageProcessor, DPTForDepthEstimation

processor = DPTImageProcessor.from_pretrained("Intel/dpt-swinv2-tiny-256")
model = DPTForDepthEstimation.from_pretrained("Intel/dpt-swinv2-tiny-256")
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)
model.eval()

def estimate_depth(frame, point):

    img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    pil = Image.fromarray(img)

    inputs = processor(images=pil, return_tensors="pt").to(device)

    with torch.no_grad():
        outputs = model(**inputs)
        pred_depth = outputs.predicted_depth 

    H, W = frame.shape[:2]
    depth_resized = torch.nn.functional.interpolate(
        pred_depth.unsqueeze(1) if pred_depth.ndim == 3 else pred_depth,
        size=(H, W),
        mode="bicubic",
        align_corners=False,
    ).squeeze().cpu().numpy()

    depth_map = depth_resized
    x, y = map(int, point)
    x = np.clip(x, 0, W - 1)
    y = np.clip(y, 0, H - 1)
    return float(depth_map[y, x]), depth_map
