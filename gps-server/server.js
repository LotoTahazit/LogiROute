import { WebSocketServer } from 'ws';
import http from 'http';
import fetch from 'node-fetch';

const OSRM_URL = 'https://router.project-osrm.org';

// Один обработчик: async prependListener + второй createServer давали 426 до конца fetch (без CORS).
const server = http.createServer((req, res) => {
  if (res.writableEnded) return;

  let url;
  try {
    url = new URL(req.url, `http://${req.headers.host}`);
  } catch {
    res.writeHead(400);
    res.end();
    return;
  }

  // Flutter: .../osrm + /route/v1/driving/... → upstream /route/v1/driving/...
  if (url.pathname === '/osrm' || url.pathname.startsWith('/osrm/')) {
    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Max-Age': '86400',
      });
      res.end();
      return;
    }

    (async () => {
      try {
        const path = url.pathname.replace(/^\/osrm/, '') || '/';
        const target = `${OSRM_URL}${path}${url.search}`;
        const response = await fetch(target, {
          method: req.method,
          headers: { 'User-Agent': 'LogiRoute-osrm-proxy/1.0' },
        });
        const data = await response.text();
        const ct = response.headers.get('content-type') || 'application/json';
        res.writeHead(response.status, {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': ct,
        });
        res.end(data);
      } catch (e) {
        console.error('OSRM proxy error:', e);
        if (!res.headersSent) {
          res.writeHead(500, {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json',
          });
          res.end(JSON.stringify({ error: 'Proxy error' }));
        }
      }
    })();
    return;
  }

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
