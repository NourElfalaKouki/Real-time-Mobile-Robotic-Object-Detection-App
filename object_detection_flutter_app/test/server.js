const http = require('http');
const socketIo = require('socket.io');

const geoJsonSamples = [
  {
    type: "FeatureCollection",
    features: [
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1658, 36.8188] },
        properties: { label: "ROBOT", timestamp: "" },
      },
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1910, 36.8028] },
        properties: { label: "DOG", timestamp: "" },
      },
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1010, 36.8460] },
        properties: { label: "CAR", timestamp: "" },
      }
    ]
  },
  {
    type: "FeatureCollection",
    features: [
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1740, 36.7999] },
        properties: { label: "ROBOT", timestamp: "" },
      },
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1500, 36.8600] },
        properties: { label: "CAR", timestamp: "" },
      },
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.2120, 36.8200] },
        properties: { label: "DOG", timestamp: "" },
      }
    ]
  },
  {
    type: "FeatureCollection",
    features: [
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1500, 36.8250] },
        properties: { label: "DOG", timestamp: "" },
      },
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1800, 36.8300] },
        properties: { label: "ROBOT", timestamp: "" },
      },
      {
        type: "Feature",
        geometry: { type: "Point", coordinates: [10.1000, 36.8000] },
        properties: { label: "CAR", timestamp: "" },
      }
    ]
  }
];

// Function to add small random variations to coordinates
function addVariation(coordinate, maxVariation = 0.001) {
  const variation = (Math.random() - 0.5) * 2 * maxVariation;
  return coordinate + variation;
}

// Function to create a varied version of the GeoJSON data
function createVariedGeoJson() {
  const sampleIndex = Math.floor(Math.random() * geoJsonSamples.length);
  const sample = JSON.parse(JSON.stringify(geoJsonSamples[sampleIndex])); // Deep copy
  
  sample.features.forEach(feature => {
    if (feature.geometry.type === "Point") {
      feature.geometry.coordinates[0] = addVariation(feature.geometry.coordinates[0]);
      feature.geometry.coordinates[1] = addVariation(feature.geometry.coordinates[1]);
      feature.properties.timestamp = new Date().toISOString();
    }
  });
  
  return sample;
}

// Create HTTP server
const server = http.createServer((req, res) => {
  if (req.url === '/test') {
    res.setHeader('Content-Type', 'text/html');
    res.writeHead(200);
    res.end(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Socket.IO GeoJSON Test</title>
        <script src="/socket.io/socket.io.js"></script>
      </head>
      <body>
        <h1>Socket.IO GeoJSON Test</h1>
        <pre id="output"></pre>
        <script>
          const socket = io();
          const output = document.getElementById('output');
          
          socket.on('connect', () => {
            console.log('Connected to server');
          });
          
          socket.on('object-detected', (data) => {
            output.textContent = JSON.stringify(data, null, 2);
            console.log('Received object-detected:', data);
          });
          
          socket.on('disconnect', () => {
            console.log('Disconnected from server');
          });
        </script>
      </body>
      </html>
    `);
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

// Create Socket.IO server
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    allowedHeaders: ["*"],
    credentials: false
  },
  transports: ['websocket', 'polling']
});

// Handle Socket.IO connections
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  // Send initial data immediately
  const initialData = createVariedGeoJson();
  socket.emit('object-detected', initialData);
  
  // Send data every 5 seconds
  const interval = setInterval(() => {
    const variedData = createVariedGeoJson();
    socket.emit('object-detected', variedData);
    console.log('Sent object-detected data to client:', socket.id);
  }, 5000);
  
  // Handle client disconnect
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
    clearInterval(interval);
  });
  
  // Handle any custom events from client
  socket.on('message', (data) => {
    console.log('Received message from client:', data);
    socket.emit('message', { response: 'Message received', data });
  });
});

const PORT = 8000;
server.listen(PORT, () => {
  console.log(`Socket.IO server running on http://localhost:${PORT}`);
  console.log('Available endpoints:');
  console.log(`  Socket.IO endpoint: ws://localhost:${PORT}`);
  console.log(`  Test page: http://localhost:${PORT}/test`);
  console.log('');
  console.log('Events emitted:');
  console.log('  - object-detected: GeoJSON data every 5 seconds');
  console.log('');
  console.log('Make sure to install socket.io: npm install socket.io');
});