// client.js
// Usage: node client.js

const io = require("socket.io-client");

// Change this URL to your server's IP and port
const SERVER_URL = "http://192.168.0.7:5000";

// Force websocket transport only to avoid polling errors
const socket = io(SERVER_URL, {
  transports: ["websocket"]
});

socket.on("connect", () => {
  console.log("✅ Connected to server with id:", socket.id);
});

socket.on("robot_position", (data) => {
  console.log("🤖 Robot position received:", data);
});

socket.on("frame_data", (data) => {
  console.log("🖼 Frame data received:", JSON.stringify(data, null, 2));
});

socket.on("disconnect", () => {
  console.log("❌ Disconnected from server");
});

socket.on("connect_error", (err) => {
  console.error("Connection error:", err.message);
});
