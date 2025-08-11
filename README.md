# Real-time-Mobile-Robotic-Object-Detection-App
This project focuses on developing a mobile application designed to display, in real-time, objects detected by a robot or smart camera using AI models. The app will feature an interactive map that visualizes these objects based on their GPS coordinates.
## Project Structure
robot_script/: Python server-side code for object detection, tracking, depth estimation, and GPS integration.

object_detection_flutter_app/: Flutter mobile application displaying detected objects in real-time on an interactive map.

## To set up the Python environmen
  ```bash
ip install -r ./robot_script/requirements.txt
  ```

### To run the python script, use the command:
  ```bash
python3 ./robot_script/main.py
  ```
### To run the flutter app 

  ```bash
cd ./object_detection_flutter_app
fluter pub get 
flutter run
  ``` 



## Notes
    Flutter SDK used version: 3.32.5 
    Ensure your Python server is running and accessible by the Flutter app.

    The Flutter app connects to the server using the configured IP and port (192.168.0.7:5000 by default).

    Modify IP addresses in the Flutter app and the python script if running on a different network.