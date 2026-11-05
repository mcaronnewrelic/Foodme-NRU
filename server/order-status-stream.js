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
 *
 * APM visibility is manual, on purpose: the upgrade bypasses Express,
 * so the agent never sees this endpoint as a web transaction. Each
 * connection is therefore wrapped in a background transaction
 * (OrderStatusStream/connection, open for the connection's lifetime)
 * and summarised at close by an OrderStreamSample custom event - the
 * server-side mirror of the browser agent's WebSocket event, which is
 * likewise emitted once per connection, at close. Telemetry is
 * best-effort throughout: it must never break the stream.
 */
const { WebSocketServer, WebSocket } = require('ws');
const defaultNewrelic = require('newrelic');

const STREAM_PATH = '/api/orders/stream';
const PING_INTERVAL_MS = 30000;

class OrderStatusStream {
  /**
   * @param logger pino-style logger
   * @param getStatus async (orderId) => status string, or null when
   *                  the order is unknown / no database is in use.
   */
  constructor(logger, getStatus, newrelic = defaultNewrelic) {
    this.logger = logger;
    this.getStatus = getStatus;
    this.newrelic = newrelic;
    this.subscribers = new Map(); // orderId -> Set<WebSocket>
    this.wss = new WebSocketServer({ noServer: true });
    this.pingTimer = null;

    this.wss.on('connection', (socket) => {
      socket.isAlive = true;
      socket.telemetry = this.beginTelemetry(socket);
      socket.on('pong', () => { socket.isAlive = true; });
      socket.on('message', (data) => {
        if (socket.telemetry) socket.telemetry.messagesReceived += 1;
        void this.handleMessage(socket, data);
      });
      socket.on('close', (code) => {
        this.endTelemetry(socket, code);
        this.unsubscribeAll(socket);
      });
      socket.on('error', () => this.unsubscribeAll(socket));
    });
  }

  /**
   * Open the connection's APM background transaction. It stays open
   * until endTelemetry releases it, so its duration is the
   * connection's lifetime; the counts land as transaction attributes
   * at the end, when they are final.
   */
  beginTelemetry(socket) {
    const telemetry = {
      orderId: null,
      messagesReceived: 0,
      messagesSent: 0,
      pushesSent: 0,
      connectedAt: Date.now(),
      release: null,
    };
    const released = new Promise((resolve) => { telemetry.release = resolve; });
    try {
      this.newrelic.startBackgroundTransaction('OrderStatusStream/connection', async () => {
        const txn = this.newrelic.getTransaction();
        await released;
        try {
          const attributes = {
            messagesReceived: telemetry.messagesReceived,
            messagesSent: telemetry.messagesSent,
            pushesSent: telemetry.pushesSent,
          };
          if (telemetry.orderId) attributes.orderId = telemetry.orderId;
          this.newrelic.addCustomAttributes(attributes);
        } catch { /* attributes are best-effort */ }
        txn?.end();
      });
    } catch { /* telemetry must never break the stream */ }
    return telemetry;
  }

  /** Close the background transaction and emit the OrderStreamSample. */
  endTelemetry(socket, closeCode) {
    const telemetry = socket.telemetry;
    if (!telemetry) return;
    socket.telemetry = null;
    telemetry.release?.();
    try {
      const attributes = {
        messagesReceived: telemetry.messagesReceived,
        messagesSent: telemetry.messagesSent,
        pushesSent: telemetry.pushesSent,
        connectedDurationMs: Date.now() - telemetry.connectedAt,
        closeCode: closeCode ?? 0,
      };
      if (telemetry.orderId) attributes.orderId = telemetry.orderId;
      this.newrelic.recordCustomEvent('OrderStreamSample', attributes);
    } catch { /* telemetry must never break the stream */ }
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
    if (socket.telemetry) socket.telemetry.orderId = orderId;
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
    for (const socket of set) {
      if (socket.readyState === WebSocket.OPEN && socket.telemetry) {
        socket.telemetry.pushesSent += 1;
      }
      this.send(socket, String(orderId), status);
    }
  }

  send(socket, orderId, status) {
    if (socket.readyState !== WebSocket.OPEN) return;
    socket.send(JSON.stringify({ type: 'status', orderId, status }));
    if (socket.telemetry) socket.telemetry.messagesSent += 1;
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
