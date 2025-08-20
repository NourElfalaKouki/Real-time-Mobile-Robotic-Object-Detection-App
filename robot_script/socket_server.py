# socket_server.py

import socketio
import json
import uvicorn
from threading import Thread

class SocketServer:
    def __init__(self, host='127.0.0.1', port=5000):
        self.host = host
        self.port = port

        self.sio = socketio.AsyncServer(
            cors_allowed_origins="*",
            async_mode="asgi",
            logger=True,
            engineio_logger=True
        )
        self.app = socketio.ASGIApp(self.sio)

        self.sio.event(self.on_connect)
        self.sio.event(self.on_disconnect)

    async def on_connect(self, sid, environ):
        print(f"✅ [SocketServer] Client connected: {sid}")

    async def on_disconnect(self, sid):
        print(f"🔌 [SocketServer] Client disconnected: {sid}")

    def send_frame_data(self, geojson_data):
        try:
            import asyncio
            asyncio.run(self._emit_data(geojson_data))
        except Exception as e:
            print(f"❌ Failed to send frame data: {e}")

    async def _emit_data(self, geojson_data):
        try:
            json_string = json.dumps(geojson_data)
            await self.sio.emit("object-detected", json_string)
            print("📤 Sent object-detected GeoJSON to all clients.")
        except Exception as e:
            print(f"❌ Emit error: {e}")

    def run(self):
        print(f"🚀 Starting ASGI Socket.IO server on {self.host}:{self.port}")
        # Run uvicorn server in this thread
        uvicorn.run(self.app, host=self.host, port=self.port, log_level="info")
