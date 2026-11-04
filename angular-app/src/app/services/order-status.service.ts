import { Injectable, computed, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

const TERMINAL = ['delivered', 'cancelled'];
const MAX_RECONNECTS = 3;
const POLL_INTERVAL_MS = 10000;
/** How long the pill keeps showing a finished order before it clears itself. */
const TERMINAL_LINGER_MS = 20000;
/** A stored order older than this is not resumed (its life is ~4 minutes). */
const RESUME_MAX_AGE_MS = 2 * 60 * 60 * 1000;
const STORAGE_KEY = 'orderup-active-order';

/** Tracker stages in lifecycle order (the pill's progress segments). */
export const ORDER_STAGES = [
  { key: 'pending', label: 'Order received' },
  { key: 'preparing', label: 'Preparing' },
  { key: 'out_for_delivery', label: 'Out for delivery' },
  { key: 'delivered', label: 'Delivered' },
] as const;

interface StatusMessage {
  type: string;
  orderId: string;
  status: string;
}

interface StoredOrder {
  orderId: string;
  restaurantName?: string;
  trackedAt: number;
}

/**
 * Live order status, shared by the Thank You tracker and the header
 * pill. Opens one WebSocket to /api/orders/stream and subscribes to a
 * single order; the order-status worker pushes each advance. If the
 * socket cannot be held, it degrades to polling GET /api/orders/:id -
 * push when possible, poll when not.
 *
 * The tracked order is persisted (localStorage) so the pill survives
 * navigation and refresh; the service resumes watching it on the
 * next page load. The service owns the channel's lifecycle - pages
 * read its signals and never stop it; a terminal status closes the
 * channel, and dismiss() forgets the order entirely.
 */
@Injectable({ providedIn: 'root' })
export class OrderStatusService {
  /** Current status of the tracked order; null until the first answer. */
  readonly status = signal<string | null>(null);
  /** True while the WebSocket (not the polling fallback) is connected. */
  readonly live = signal(false);
  /** Restaurant of the tracked order, for the pill's label. */
  readonly restaurantName = signal<string | null>(null);
  /** Whether the header pill should be on screen. */
  readonly pillVisible = signal(false);

  /** Index into ORDER_STAGES for the current status, or -1. */
  readonly stageIndex = computed(() => {
    const status = this.status();
    return ORDER_STAGES.findIndex((stage) => stage.key === status);
  });

  /** Human label for the current status (stage wording, else the raw value). */
  readonly statusLabel = computed(() => {
    const status = this.status();
    if (!status) return 'Checking for updates…';
    if (status === 'cancelled') return 'Cancelled';
    const stage = ORDER_STAGES.find((s) => s.key === status);
    return stage ? stage.label : status;
  });

  private socket: WebSocket | null = null;
  private orderId: string | null = null;
  private reconnects = 0;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private pollTimer: ReturnType<typeof setInterval> | null = null;
  private lingerTimer: ReturnType<typeof setTimeout> | null = null;
  private stopped = true;

  constructor(private http: HttpClient) {
    this.resume();
  }

  track(orderId: string, restaurantName?: string): void {
    this.teardownChannel();
    this.clearLinger();
    this.stopped = false;
    this.orderId = orderId;
    this.restaurantName.set(restaurantName ?? null);
    this.status.set(null);
    this.reconnects = 0;
    this.pillVisible.set(true);
    this.persist();
    // Seed from REST so the tracker paints immediately; the socket's
    // snapshot and pushes take it from there.
    this.fetchOnce();
    this.connect();
  }

  /** Forget the tracked order: close the channel, clear the pill and storage. */
  dismiss(): void {
    this.teardownChannel();
    this.clearLinger();
    this.stopped = true;
    this.orderId = null;
    this.restaurantName.set(null);
    this.pillVisible.set(false);
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      /* storage unavailable */
    }
  }

  /** Resume a persisted order (fresh page load), if it is not stale. */
  private resume(): void {
    let stored: StoredOrder | null = null;
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) stored = JSON.parse(raw) as StoredOrder;
    } catch {
      stored = null;
    }
    if (!stored?.orderId || Date.now() - stored.trackedAt > RESUME_MAX_AGE_MS) {
      if (stored) this.dismiss();
      return;
    }
    this.stopped = false;
    this.orderId = stored.orderId;
    this.restaurantName.set(stored.restaurantName ?? null);
    this.pillVisible.set(true);
    this.fetchOnce();
    this.connect();
  }

  private persist(): void {
    if (!this.orderId) return;
    const stored: StoredOrder = {
      orderId: this.orderId,
      restaurantName: this.restaurantName() ?? undefined,
      trackedAt: Date.now(),
    };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(stored));
    } catch {
      /* storage unavailable: the pill just won't survive a refresh */
    }
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
      // Nothing more will change: close the channel down politely,
      // linger the pill a little so the ending is seen, then forget
      // the order (storage only - the page keeps its final status).
      this.teardownChannel();
      this.clearLinger();
      this.lingerTimer = setTimeout(() => {
        this.pillVisible.set(false);
        try {
          localStorage.removeItem(STORAGE_KEY);
        } catch {
          /* storage unavailable */
        }
      }, TERMINAL_LINGER_MS);
    }
  }

  private teardownChannel(): void {
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

  private clearLinger(): void {
    if (this.lingerTimer) clearTimeout(this.lingerTimer);
    this.lingerTimer = null;
  }
}
