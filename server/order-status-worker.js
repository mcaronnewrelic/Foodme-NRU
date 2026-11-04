/**
 * Order status worker (spec section 11.2, I11's prerequisite feature).
 *
 * Until now nothing ever updated orders.status: it was written
 * 'pending' at insert and stayed there forever. This worker is an
 * in-process poller that advances orders through their lifecycle by
 * age - pending -> preparing (45s) -> out_for_delivery (+75s) ->
 * delivered (+75s), about three minutes end to end - so My Orders
 * actually moves.
 *
 * Design notes, all deliberate:
 *  - It runs on its OWN pg client, never the app's single client
 *    (server/database.js). The separation is what lets the worker be
 *    sick without the site noticing - the whole premise of I11.
 *  - It claims everything that is not finished (status NOT IN
 *    ('delivered', 'cancelled')), oldest first, a few hundred per
 *    poll, and advances the claimed batch inside ONE transaction:
 *    a poll either advances everyone it claimed or no one. That
 *    atomicity is the flaw I11 arms - one row the worker cannot
 *    classify aborts the batch for everybody.
 *  - Each poll is an APM background transaction
 *    (OrderStatusWorker/poll) and records an OrderPipelineSample
 *    custom event (counts per status, how many advanced, the oldest
 *    unfinished order's age), which is what the Overview dashboard's
 *    Order pipeline widgets chart.
 *
 * Timing is env-tunable for local testing: ORDER_STATUS_POLL_MS,
 * ORDER_STATUS_PENDING_SECONDS, ORDER_STATUS_PREPARING_SECONDS,
 * ORDER_STATUS_OUT_SECONDS.
 */
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
const newrelic = require('newrelic');

const NEXT = {
  pending: 'preparing',
  preparing: 'out_for_delivery',
  out_for_delivery: 'delivered',
};
const TERMINAL = ['delivered', 'cancelled'];
const BATCH_LIMIT = 500;

function secondsFromEnv(name, fallback) {
  const n = Number(process.env[name]);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

/** Same connection parameters as DatabaseService / demo-investigations. */
function workerClientConfig() {
  if (process.env.DATABASE_URL) {
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    };
  }
  let dbPass = process.env.DB_PASSWORD;
  const passwordFile = path.join(__dirname, '../db/password.txt');
  if (!dbPass && fs.existsSync(passwordFile)) {
    try { dbPass = fs.readFileSync(passwordFile, 'utf8').trim(); } catch { /* fall through */ }
  }
  if (!dbPass) dbPass = 'orderup_secure_password_2025!';
  const config = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'orderup',
    user: process.env.DB_USER || 'orderup_user',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  };
  config.password = dbPass;
  return config;
}

class OrderStatusWorker {
  constructor(logger) {
    this.logger = logger;
    this.client = null;
    this.timer = null;
    // Optional: fn(changed) called after each committed batch with
    // [{ id, orderNumber, status }] - start.js wires it to the live
    // order-status stream. The worker itself knows nothing about
    // sockets.
    this.onAdvance = null;
    const pollEnv = Number(process.env.ORDER_STATUS_POLL_MS);
    this.pollMs = Number.isFinite(pollEnv) && pollEnv > 0 ? pollEnv : 20000;
    this.stageSeconds = {
      pending: secondsFromEnv('ORDER_STATUS_PENDING_SECONDS', 45),
      preparing: secondsFromEnv('ORDER_STATUS_PREPARING_SECONDS', 75),
      out_for_delivery: secondsFromEnv('ORDER_STATUS_OUT_SECONDS', 75),
    };
  }

  start() {
    if (this.timer) return;
    this.logger?.info({ pollMs: this.pollMs, stageSeconds: this.stageSeconds }, 'Order status worker started');
    const tick = () => { this.poll().catch(() => {}); };
    this.timer = setInterval(tick, this.pollMs);
    this.timer.unref?.();
    tick();
  }

  stop() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    if (this.client) { this.client.end().catch(() => {}); this.client = null; }
  }

  async ensureClient() {
    if (this.client) return this.client;
    const client = new Client(workerClientConfig());
    client.on('error', () => { if (this.client === client) this.client = null; });
    await client.connect();
    this.client = client;
    return client;
  }

  /** One poll, wrapped as an APM background transaction. */
  async poll() {
    const worker = this;
    await newrelic.startBackgroundTransaction('OrderStatusWorker/poll', async () => {
      const txn = newrelic.getTransaction();
      try {
        const advanced = await worker.advanceBatch();
        txn.end();
        return advanced;
      } catch (err) {
        newrelic.noticeError(err);
        worker.logger?.warn({ err }, 'Order status worker: poll failed, batch rolled back');
        txn.end();
        return 0;
      }
    });
  }

  async advanceBatch() {
    const client = await this.ensureClient();

    const { rows: claimed } = await client.query(
      `SELECT id, order_number, status, created_at, updated_at
         FROM orders
        WHERE status NOT IN ($1, $2)
        ORDER BY created_at ASC
        LIMIT $3`,
      [TERMINAL[0], TERMINAL[1], BATCH_LIMIT],
    );

    const now = Date.now();
    const due = claimed.filter(o => {
      // Time in the current stage: from creation for the first stage,
      // from the last transition after that. An unrecognised status
      // is treated with the first stage's age - it claims a row it
      // then cannot classify, which is exactly I11's poison path.
      const stageAge = this.stageSeconds[o.status] ?? this.stageSeconds.pending;
      const since = o.status === 'pending' ? new Date(o.created_at).getTime() : new Date(o.updated_at).getTime();
      return now - since >= stageAge * 1000;
    });

    let advanced = 0;
    const changed = [];
    if (due.length) {
      await client.query('BEGIN');
      try {
        for (const order of due) {
          const next = NEXT[order.status];
          if (!next) {
            throw new Error(`Unknown order status: "${order.status}" (order ${order.order_number})`);
          }
          await client.query('UPDATE orders SET status = $1, updated_at = now() WHERE id = $2', [next, order.id]);
          advanced += 1;
          changed.push({ id: order.id, orderNumber: order.order_number, status: next });
        }
        await client.query('COMMIT');
      } catch (err) {
        await client.query('ROLLBACK').catch(() => {});
        throw err;
      }
      // Notify live watchers (the order-status stream) only after the
      // commit lands, and never let a broken notifier fail the poll.
      if (changed.length && this.onAdvance) {
        try { this.onAdvance(changed); } catch { /* notifier is best-effort */ }
      }
    }

    await this.recordSample(client, advanced);
    return advanced;
  }

  async recordSample(client, advanced) {
    const { rows } = await client.query(
      `SELECT status, count(*)::int AS n,
              min(created_at) AS oldest
         FROM orders
        WHERE status NOT IN ($1, $2)
        GROUP BY status`,
      [TERMINAL[0], TERMINAL[1]],
    );
    const counts = { pending: 0, preparing: 0, outForDelivery: 0, other: 0 };
    let oldestAgeSeconds = 0;
    for (const row of rows) {
      if (row.status === 'pending') counts.pending = row.n;
      else if (row.status === 'preparing') counts.preparing = row.n;
      else if (row.status === 'out_for_delivery') counts.outForDelivery = row.n;
      else counts.other += row.n;
      if (row.oldest) {
        oldestAgeSeconds = Math.max(oldestAgeSeconds, Math.round((Date.now() - new Date(row.oldest).getTime()) / 1000));
      }
    }
    const { rows: total } = await client.query('SELECT count(*)::int AS n FROM orders WHERE status NOT IN ($1, $2)', [TERMINAL[0], TERMINAL[1]]);
    newrelic.recordCustomEvent('OrderPipelineSample', {
      pending: counts.pending,
      preparing: counts.preparing,
      outForDelivery: counts.outForDelivery,
      otherStatus: counts.other,
      unfinished: total[0].n,
      advanced,
      oldestUnfinishedAgeSeconds: oldestAgeSeconds,
    });
  }
}

module.exports = OrderStatusWorker;
