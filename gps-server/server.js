import { WebSocketServer } from 'ws';
import http from 'http';

const server = http.createServer((req, res) => {
  // Health check для Cloud Run
  if (req.url === '/health') {
    res.writeHead(200);
    res.end('ok');
    return;
  }
  res.writeHead(426);
  res.end('WebSocket only');
});

const wss = new WebSocketServer({ server });

// Последние координаты водителей в памяти
// Map<driverId, {lat, lng, speed, driverName, timestamp}>
const drivers = new Map();

// Подписчики (диспетчеры)
const dispatchers = new Set();

wss.on('connection', (ws) => {
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });

  ws.on('message', (msg) => {
    try {
      const data = JSON.parse(msg);

      // DRIVER GPS UPDATE
      if (data.type === 'gps') {
        const { driverId, driverName, lat, lng, speed } = data;
        if (!driverId || lat == null || lng == null) return;

        drivers.set(driverId, {
          lat,
          lng,
          speed: speed || 0,
          driverName: driverName || '',
          timestamp: Date.now(),
        });

        // Рассылаем диспетчерам
        const payload = JSON.stringify({
          type: 'driver_update',
          driverId,
          driverName: driverName || '',
          lat,
          lng,
          speed: speed || 0,
        });

        for (const d of dispatchers) {
          if (d.readyState === 1) d.send(payload);
        }
      }

      // DISPATCHER CONNECT
      if (data.type === 'dispatcher') {
        dispatchers.add(ws);

        // Отправить текущие позиции всех водителей
        const snapshot = {};
        for (const [id, loc] of drivers) {
          // Только свежие (< 60 мин)
          if (Date.now() - loc.timestamp < 60 * 60 * 1000) {
            snapshot[id] = loc;
          }
        }
        ws.send(JSON.stringify({ type: 'snapshot', drivers: snapshot }));
      }
    } catch (e) {
      console.error('Message parse error:', e.message);
    }
  });

  ws.on('close', () => {
    dispatchers.delete(ws);
  });
});

// Ping/pong для keepalive
const pingInterval = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!ws.isAlive) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

// Очистка устаревших водителей (> 2 часа)
setInterval(() => {
  const cutoff = Date.now() - 2 * 60 * 60 * 1000;
  for (const [id, loc] of drivers) {
    if (loc.timestamp < cutoff) drivers.delete(id);
  }
}, 5 * 60 * 1000);

wss.on('close', () => clearInterval(pingInterval));

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`GPS WebSocket server running on port ${PORT}`);
  console.log(`Clients: ws://localhost:${PORT}`);
});
