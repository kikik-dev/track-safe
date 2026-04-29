const { WebSocketServer } = require('ws');

const port = process.env.PORT || 8080;
const wss = new WebSocketServer({ port });

// Store active users globally
// Format: { userId: { lat, lng, speed, timestamp } }
const activeUsers = new Map();

wss.on('connection', function connection(ws) {
  console.log('Client connected');

  ws.on('message', function message(data) {
    try {
      const parsedData = JSON.parse(data);
      
      // If it's a location update from a client
      if (parsedData.type === 'location_update') {
        const { userId, lat, lng, speed } = parsedData.payload;
        
        activeUsers.set(userId, {
          userId,
          lat,
          lng,
          speed,
          timestamp: Date.now()
        });

        // Broadcast updated user map to ALL clients
        const allUsersList = Array.from(activeUsers.values());
        const broadcastPayload = JSON.stringify({
          type: 'all_users',
          payload: allUsersList
        });

        wss.clients.forEach(function each(client) {
          if (client.readyState === 1) { // WebSocket.OPEN == 1
            client.send(broadcastPayload);
          }
        });
      }
    } catch (e) {
      console.error('Error parsing message:', e);
    }
  });

  ws.on('close', () => {
    console.log('Client disconnected');
    // Note: In a production scenario, you would track which user disconnected
    // and remove them from `activeUsers` after a timeout.
  });
});

console.log(`TrackSafe WebSocket server running on ws://localhost:${port}`);
