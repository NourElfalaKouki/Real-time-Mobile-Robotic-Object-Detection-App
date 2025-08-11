# Real-time-Mobile-Robotic-Object-Detection-App
This project focuses on developing a mobile application designed to display, in real-time, objects detected by a robot or smart camera using AI models. The app will feature an interactive map that visualizes these objects based on their GPS coordinates.
## To set up the Python environmen
pip install -r ./robot_script/requirements.txt

### To run the python script, use the command:
python3 ./robot_script/main.py


## Notes

    Ensure your Python server is running and accessible by the Flutter app.

    The Flutter app connects to the server using the configured IP and port (192.168.0.7:5000 by default).

    Modify IP addresses in the Flutter app and the python script if running on a different network.