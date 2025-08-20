# Real-time Mobile Robotic Object Detection App

This project focuses on developing a mobile application designed to display, in real-time, objects detected by a robot or smart camera using AI models. The app features an interactive map that visualizes detected objects based on their GPS coordinates and includes user authentication.

## Project Structure

* `robot_script/` - Python server-side code for:

  * Object detection
  * Object tracking
  * Depth estimation
  * GPS integration
  * Real-time data transmission via WebSockets

* `object_detection_flutter_app/` - Flutter mobile application for:

  * Real-time visualization of detected objects on an interactive map
  * Detection history
  * User authentication

* `auth_server/` - Node.js authentication server for:

  * User registration and login
  * Secure password hashing with bcrypt
  * MySQL database integration

## Prerequisites

* Python 3.8+
* Node.js 
* MySQL 
* Flutter SDK 3.32.5

## Setup Instructions

### 1. Python Environment

Install dependencies:

```bash
pip install -r ./robot_script/requirements.txt
```

### 2. Node.js Authentication Server

Navigate to the authentication server directory and install dependencies:

```bash
cd auth_server
npm install
```

### 3. MySQL Database Setup

1. Install MySQL on your system if not already installed
2. Log in to MySQL:

```bash
mysql -u root -p
```

3. Create the database and table:

```sql
CREATE DATABASE IF NOT EXISTS auth_db;

USE auth_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

4. Exit MySQL:

```sql
EXIT;
```

### 4. Configuration

> **Note:** The `.env` files are already included in the repository. **You must update them with your system and network settings before running the servers or the app.**

#### Python Server Configuration (`robot_script/.env`)

```ini
HOST=192.168.1.17         # Change to your server IP
PORT=5000                 # Change if needed
GPS_PORT=/dev/ttyUSB0     # Change to your GPS device port
GPS_BAUDRATE=9600         # Change if your GPS uses a different baud rate
```

#### Authentication Server Configuration (`auth_server/.env`)

```ini
DB_HOST=localhost
DB_USER=your_mysql_username      # Replace with your MySQL username
DB_PASSWORD=your_mysql_password  # Replace with your MySQL password
DB_NAME=auth_db
PORT=9000
```

#### Flutter Application Configuration (`object_detection_flutter_app/.env`)

```ini
API_URL=http://192.168.1.17:9000    # Change to your authentication server URL
SOCKET_URL=http://192.168.1.17:5000 # Change to your Python server URL
```

### 5. Running the Application

1. **Start the authentication server:**

```bash
cd auth_server
npm start
```

2. **Start the Python server** (in a new terminal):

```bash
# Option 1 - Normal mode (no GPS offset)
python3 ./robot_script/main.py

# Option 2 - Test mode (adds GPS offset to detections)
python3 ./robot_script/test.py
```

3. **Run the Flutter application** (in a new terminal):

```bash
cd ./object_detection_flutter_app
flutter pub get
flutter run
```

> ⚠️ Make sure all `.env` files are properly updated before running the servers and app.

## Usage

1. Open the Flutter application on your mobile device
2. Create an account or login with existing credentials
3. Ensure the Python server is running and detecting objects
4. View detected objects in real-time on the interactive map
5. Use the app to filter and review detection history

## API Endpoints

### Authentication Server

* `POST /signup` - Create a new user account
* `POST /login` - Authenticate an existing user

### Python Server

* WebSocket connection for real-time object data
* Sends GeoJSON formatted detection data