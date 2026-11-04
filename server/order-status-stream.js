/**
 * Live order status over WebSocket (phase 1: the Thank You tracker).
 *
 * The order-status worker advances orders in Postgres; this module is
 * the push channel that lets a browser watch its own order move
 * (pending -> preparing -> out_for_delivery -> delivered) instead of
 * re-loading My Orders. The worker stays transport-agnostic: start.js
 * wires its onAdvance callback to this module's publish().
 *
 * Protocol (JSON both ways):
 *  - client -> server: { type: 'subscribe', orderId }
 *  - server -> client: { type: 'status', orderId, status }
 *    Sent once as a snapshot when the subscription lands (looked up
 *    through the app's normal order read, so it answers even while
 *    the worker is sick), then again on every worker advance.
 *
 * The endpoint lives under /api/ on purpose: the nginx /api/ location
 * already forwards the Upgrade headers and the ALB passes WebSocket
 * upgrades through, so no infrastructure change was needed. A 30s
 * ping keeps connections ahead of the ALB's idle timeout.
 */
const { WebSocketServer, WebSocket } = require('ws');

const STREAM_PATH = '/api/orders/stream';
const PING_INTERVAL_MS = 30000;

class OrderStatusStream {
  /**
   * @param logger pino-style logger
   * @param getStatus async (orderId) => status string, or null when
   *                  the order is unknown / no database is in use.
   */
  constructor(logger, getStatus) {
    this.logger = logger;
    this.getStatus = getStatus;
    this.subscribers = new Map(); // orderId -> Set<WebSocket>
    this.wss = new WebSocketServer({ noServer: true });
    this.pingTimer = null;

    this.wss.on('connection', (socket) => {
      socket.isAlive = true;
      socket.on('pong', () => { socket.isAlive = true; });
      socket.on('message', (data) => { void this.handleMessage(socket, data); });
      socket.on('close', () => this.unsubscribeAll(socket));
      socket.on('error', () => this.unsubscribeAll(socket));
    });
  }

  /** Hook the HTTP server's upgrade event; only the stream path is claimed. */
  attach(server) {
    server.on('upgrade', (request, socket, head) => {
      let pathname;
      try {
        pathname = new URL(request.url, 'http://localhost').pathname;
      } catch {
        pathname = request.url;
      }
      if (pathname !== STREAM_PATH) {
        socket.destroy();
        return;
      }
      this.wss.handleUpgrade(request, socket, head, (ws) => {
        this.wss.emit('connection', ws, request);
      });
    });
    this.pingTimer = setInterval(() => {
      for (const socket of this.wss.clients) {
        if (socket.isAlive === false) { socket.terminate(); continue; }
        socket.isAlive = false;
        socket.ping();
      }
    }, PING_INTERVAL_MS);
    this.pingTimer.unref?.();
    this.logger?.info({ path: STREAM_PATH }, 'Order status stream attached');
  }

  async handleMessage(socket, data) {
    let message;
    try {
      message = JSON.parse(String(data));
    } catch {
      return; // Not JSON: not our protocol, ignore.
    }
    if (message?.type !== 'subscribe' || message.orderId == null) return;
    const orderId = String(message.orderId);
    let set = this.subscribers.get(orderId);
    if (!set) {
      set = new Set();
      this.subscribers.set(orderId, set);
    }
    set.add(socket);
    // Snapshot: the subscriber's first paint, and the answer it keeps
    // if the worker never advances the order (I11's freeze included).
    let status = null;
    try {
      status = await this.getStatus(orderId);
    } catch (err) {
      this.logger?.warn({ err, orderId }, 'Order status stream: snapshot lookup failed');
    }
    this.send(socket, orderId, status ?? 'pending');
  }

  /** Called by the worker wiring for every order it advanced. */
  publish(orderId, status) {
    const set = this.subscribers.get(String(orderId));
    if (!set) return;
    for (const socket of set) this.send(socket, String(orderId), status);
  }

  send(socket, orderId, status) {
    if (socket.readyState !== WebSocket.OPEN) return;
    socket.send(JSON.stringify({ type: 'status', orderId, status }));
  }

  unsubscribeAll(socket) {
    for (const [orderId, set] of this.subscribers) {
      set.delete(socket);
      if (set.size === 0) this.subscribers.delete(orderId);
    }
  }

  close() {
    if (this.pingTimer) clearInterval(this.pingTimer);
    this.pingTimer = null;
    for (const socket of this.wss.clients) socket.terminate();
    this.wss.close();
    this.subscribers.clear();
  }
}

module.exports = OrderStatusStream;
