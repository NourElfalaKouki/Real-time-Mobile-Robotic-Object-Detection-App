import serial
import io
import pynmea2
import threading

class GPSReader:
    def __init__(self, port='/dev/ttyUSB0', baudrate=9600):
        self.port = port
        self.baudrate = baudrate

        self.gps_lat = None
        self.gps_lon = None
        self.gps_alt = None

        self._connected = False  # True if serial port opens
        self._available = False  # True if GPS fix/data received

        self.running = False
        self.lock = threading.Lock()
        self.thread = None

        # ✅ Check if device exists at init
        try:
            test_serial = serial.Serial(self.port, self.baudrate, timeout=1)
            test_serial.close()
            self._connected = True
            print(f"[GPSReader] ✔ GPS device found on {self.port}")
        except serial.SerialException as e:
            print(f"[GPSReader] ✖ No GPS device found on {self.port}: {e}")
            self._connected = False

    def start(self):
        if not self._connected:
            print("[GPSReader] Cannot start: GPS device not connected.")
            return
        if not self.running:
            self.running = True
            self.thread = threading.Thread(target=self._gps_loop, daemon=True)
            self.thread.start()
            print(f"🚀 GPSReader started on port {self.port} at {self.baudrate} baud.")

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join()
            print("🛑 GPSReader stopped.")

    def _gps_loop(self):
        try:
            ser = serial.Serial(self.port, self.baudrate, timeout=1)
            sio = io.TextIOWrapper(io.BufferedRWPair(ser, ser))
            while self.running:
                try:
                    line = sio.readline()
                    if not line:
                        continue
                    msg = pynmea2.parse(line)
                    if hasattr(msg, 'latitude') and hasattr(msg, 'longitude'):
                        with self.lock:
                            self.gps_lat = msg.latitude
                            self.gps_lon = msg.longitude
                            self.gps_alt = getattr(msg, 'altitude', None)
                            self._available = True
                except pynmea2.ParseError:
                    continue
                except Exception as e:
                    print(f"[GPSReader] Error parsing NMEA: {e}")
        except Exception as e:
            print(f"[GPSReader] Failed to open serial port during _gps_loop: {e}")

    def get_location(self, timeout=2):
        import time
        start = time.time()
        while time.time() - start < timeout:
            with self.lock:
                if self.gps_lat is not None and self.gps_lon is not None:
                    return self.gps_lat, self.gps_lon, self.gps_alt
            time.sleep(0.1)
        return None, None, None

    def is_connected(self):
        return self._connected

    def is_available(self):
        with self.lock:
            return self._available
