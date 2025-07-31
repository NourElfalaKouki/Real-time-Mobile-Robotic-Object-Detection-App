import cv2
import numpy as np

class WebcamCamera:
    def __init__(self, cam_index=0):
        self.cap = cv2.VideoCapture(cam_index)

    def get_frame(self):
        ret, frame = self.cap.read()
        if not ret:
            return None, None
        return frame, None

    def release(self):
        self.cap.release()

    def compute_average_depth(self, x1, y1, x2, y2, depth_frame):
        return None 