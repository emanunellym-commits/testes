import http from 'node:http';
import { WebSocketServer, WebSocket } from 'ws';

const port = Number(process.env.PORT || 8080);
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ ok: true, service: 'livechat-v13' }));
    return;
  }

  res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
  res.end('LiveChat V13 WebSocket server is online.');
});

const wss = new WebSocketServer({ server });
const clients = new Map();

function cleanName(value) {
  return String(value ?? '')
    .trim()
    .replace(/[^\p{L}\p{N} _.-]/gu, '')
    .slice(0, 32);
}

function send(ws, payload) {
  if (ws?.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(payload));
  }
}

function broadcastPresence() {
  const users = [...clients.keys()].sort((a, b) => a.localeCompare(b));
  const payload = JSON.stringify({ type: 'presence', users });
  for (const ws of clients.values()) {
    if (ws.readyState === WebSocket.OPEN) ws.send(payload);
  }
}

wss.on('connection', (ws) => {
  let name = null;
  let lastNudgeAt = 0;

  ws.on('message', (raw) => {
    let data;
    try {
      data = JSON.parse(raw.toString());
    } catch {
      return;
    }

    if (data.type === 'hello') {
      const requested = cleanName(data.name);
      if (requested.length < 2) {
        send(ws, { type: 'error', message: 'Apelido inválido' });
        return;
      }

      if (clients.has(requested) && clients.get(requested) !== ws) {
        send(ws, { type: 'error', message: 'Esse apelido já está online' });
        return;
      }

      if (name && clients.get(name) === ws) clients.delete(name);
      name = requested;
      clients.set(name, ws);
      send(ws, { type: 'hello.ok', name });
      broadcastPresence();
      return;
    }

    if (!name) {
      send(ws, { type: 'error', message: 'Identifique-se primeiro' });
      return;
    }

    if (data.type === 'message') {
      const to = cleanName(data.to);
      const text = String(data.text ?? '').trim().slice(0, 2000);
      if (!to || !text) return;

      const target = clients.get(to);
      if (!target) {
        send(ws, { type: 'delivery.failed', to, reason: 'offline' });
        return;
      }

      send(target, {
        type: 'message',
        from: name,
        text,
        sentAt: new Date().toISOString(),
      });
      send(ws, { type: 'delivery.ok', to, sentAt: new Date().toISOString() });
      return;
    }

    if (data.type === 'nudge') {
      const now = Date.now();
      if (now - lastNudgeAt < 5000) {
        send(ws, { type: 'error', message: 'Espere alguns segundos para chamar atenção de novo.' });
        return;
      }

      const to = cleanName(data.to);
      const target = clients.get(to);
      if (!target) return;

      lastNudgeAt = now;
      send(target, { type: 'nudge', from: name });
    }
  });

  ws.on('close', () => {
    if (name && clients.get(name) === ws) {
      clients.delete(name);
      broadcastPresence();
    }
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`LiveChat V13 listening on port ${port}`);
});
