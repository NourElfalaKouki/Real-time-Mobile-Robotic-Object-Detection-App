import socketio
import eventlet

class SocketServer:
    def __init__(self, host='0.0.0.0', port=3000):
        self.sio = socketio.Server(cors_allowed_origins="*")
        self.app = socketio.WSGIApp(self.sio)
        self.host = host
        self.port = port

        self.sio.event(self.on_connect)
        self.sio.event(self.on_disconnect)

    def on_connect(self, sid, environ):
        print(f"Client connected: {sid}")

    def on_disconnect(self, sid):
        print(f"Client disconnected: {sid}")

    def send_robot_position(self, data):
        self.sio.emit("robot_position", data)

    def send_frame_data(self, geojson_data):
        self.sio.emit("frame_data", geojson_data)

    def run(self):
        print(f"Starting server on {self.host}:{self.port}")
        eventlet.wsgi.server(eventlet.listen((self.host, self.port)), self.app)
