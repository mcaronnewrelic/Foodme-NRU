import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

const TERMINAL = ['delivered', 'cancelled'];
const MAX_RECONNECTS = 3;
const POLL_INTERVAL_MS = 10000;

interface StatusMessage {
  type: string;
  orderId: string;
  status: string;
}

/**
 * Live order status for the Thank You tracker (and, later, the header
 * pill). Opens one WebSocket to /api/orders/stream and subscribes to a
 * single order; the order-status worker pushes each advance. If the
 * socket cannot be held, it degrades to polling GET /api/orders/:id -
 * push when possible, poll when not.
 */
@Injectable({ providedIn: 'root' })
export class OrderStatusService {
  /** Current status of the tracked order; null until the first answer. */
  readonly status = signal<string | null>(null);
  /** True while the WebSocket (not the polling fallback) is connected. */
  readonly live = signal(false);

  private socket: WebSocket | null = null;
  private orderId: string | null = null;
  private reconnects = 0;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private pollTimer: ReturnType<typeof setInterval> | null = null;
  private stopped = true;

  constructor(private http: HttpClient) {}

  track(orderId: string): void {
    this.stop();
    this.stopped = false;
    this.orderId = orderId;
    this.status.set(null);
    this.reconnects = 0;
    // Seed from REST so the tracker paints immediately; the socket's
    // snapshot and pushes take it from there.
    this.fetchOnce();
    this.connect();
  }

  stop(): void {
    this.stopped = true;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.reconnectTimer = null;
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.pollTimer = null;
    if (this.socket) {
      this.socket.onclose = null;
      this.socket.close();
      this.socket = null;
    }
    this.live.set(false);
  }

  private connect(): void {
    if (this.stopped || !this.orderId) return;
    const scheme = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    let socket: WebSocket;
    try {
      socket = new WebSocket(`${scheme}//${window.location.host}/api/orders/stream`);
    } catch {
      this.startPolling();
      return;
    }
    this.socket = socket;

    socket.onopen = () => {
      this.live.set(true);
      this.reconnects = 0;
      socket.send(JSON.stringify({ type: 'subscribe', orderId: this.orderId }));
    };
    socket.onmessage = (event) => {
      try {
        const message = JSON.parse(String(event.data)) as StatusMessage;
        if (message.type === 'status' && String(message.orderId) === this.orderId) {
          this.applyStatus(message.status);
        }
      } catch {
        /* not our protocol */
      }
    };
    socket.onclose = () => {
      this.live.set(false);
      if (this.stopped || !this.orderId) return;
      if (TERMINAL.includes(this.status() ?? '')) return;
      if (this.reconnects < MAX_RECONNECTS) {
        const delay = 1000 * 2 ** this.reconnects;
        this.reconnects += 1;
        this.reconnectTimer = setTimeout(() => this.connect(), delay);
      } else {
        this.startPolling();
      }
    };
    socket.onerror = () => socket.close();
  }

  private startPolling(): void {
    if (this.pollTimer || this.stopped) return;
    this.pollTimer = setInterval(() => this.fetchOnce(), POLL_INTERVAL_MS);
  }

  private fetchOnce(): void {
    if (!this.orderId) return;
    this.http.get<{ status?: string }>(`/api/orders/${this.orderId}`).subscribe({
      next: (order) => {
        if (order?.status) this.applyStatus(order.status);
      },
      error: () => {
        /* the tracker keeps its last known status */
      },
    });
  }

  private applyStatus(status: string): void {
    this.status.set(status);
    if (TERMINAL.includes(status)) {
      // Nothing more will change: close the channel down politely.
      if (this.pollTimer) {
        clearInterval(this.pollTimer);
        this.pollTimer = null;
      }
      if (this.socket) {
        this.socket.onclose = null;
        this.socket.close();
        this.socket = null;
      }
      this.live.set(false);
    }
  }
}
