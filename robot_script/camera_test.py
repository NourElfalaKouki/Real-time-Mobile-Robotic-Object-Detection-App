import cv2

for i in range(3):
    cap = cv2.VideoCapture(i)
    if cap.isOpened():
        print(f"Camera {i} opened successfully!")
        cap.release()
    else:
        print(f"Camera {i} failed to open.")
