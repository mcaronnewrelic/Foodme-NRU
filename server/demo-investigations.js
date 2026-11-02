/**
 * Demo investigations (spec section 11): which investigation, if any, is
 * armed right now. Mirrors demo-failures.js, minus the rotation -
 * investigations are deliberate, never ambient.
 *
 * Priority:
 *   1. Env - DEMO_NGINX_502=1 arms "The 502 didn't come from the app"
 *      (I5); DEMO_DB_SLOW_ORDER_QUERY=<seconds> arms "It's not checkout"
 *      (I2): every order runs a pg_sleep of that many seconds inside its
 *      database work, so the order transaction's time sits in one
 *      datastore span; DEMO_DB_LOCK=1 arms "The table is locked" (I7);
 *      DEMO_DB_BIG_ORDERS=1 arms "The slow lookup" (I8).
 *   2. Manual override - POST /api/demo/investigations (the How It Works
 *      instructor controls), persisted to data/demo-investigations.json
 *      so an arm survives restarts. {slug: 'off'} disarms until cleared.
 * One investigation armed at a time.
 *
 * I7 and I8 have side effects beyond a flag, driven by syncSideEffects()
 * (called at boot and after every arm change) through a DEDICATED pg
 * client - never the app's single client:
 *   I7 - a helper transaction holds LOCK TABLE orders IN EXCLUSIVE MODE
 *        (blocks order INSERTs, not reads) for a hard 15-minute window
 *        (acceptance A12: it cannot outlive the window; disarm, the
 *        timer, or the connection dying all release it). The helper
 *        sleeps client-side, so its session reads 'idle in transaction'
 *        - the exact state the investigation teaches students to find.
 *   I8 - the server seeds synthetic order history (customers whose
 *        phones carry the (503) 555-7 prefix, orders numbered SEED-*)
 *        until the unindexed customers.phone lookup has a table worth
 *        scanning; the instructor applies the fix (CREATE INDEX) via
 *        POST {action: 'apply-index'}, and disarming deletes the seed
 *        (cascades take orders and items with the customers) and drops
 *        the demo index.
 */
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

const STATE_FILE = path.join(__dirname, 'data', 'demo-investigations.json');
const SLUG_SLOW_ORDER = 'its-not-checkout';
const SLUG_NGINX_502 = 'the-502-didnt-come-from-the-app';
const SLUG_SINGLE_CONNECTION = 'one-connection-for-the-whole-restaurant';
const SLUG_TABLE_LOCKED = 'the-table-is-locked';
const SLUG_SLOW_LOOKUP = 'the-slow-lookup';
const KNOWN_SLUGS = [SLUG_SLOW_ORDER, SLUG_NGINX_502, SLUG_SINGLE_CONNECTION, SLUG_TABLE_LOCKED, SLUG_SLOW_LOOKUP];
const DEFAULT_SECONDS = 3;
const MAX_SECONDS = 10;

const LOCK_WINDOW_MS = 15 * 60 * 1000;
const SEED_CUSTOMERS = 200000;
const SEED_PHONE_PREFIX = '(503) 555-7';
const SEED_INDEX = 'idx_customers_phone_demo';

function clampSeconds(value) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_SECONDS;
  return Math.min(Math.max(Math.round(n), 1), MAX_SECONDS);
}

function envTruthy(name) {
  const v = process.env[name];
  return !!v && v !== '0' && v !== 'off';
}

/** Same connection parameters as DatabaseService (server/database.js). */
function adminClientConfig() {
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
  if (!dbPass) dbPass = 'foodme_secure_password_2025!';
  const config = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'foodme',
    user: process.env.DB_USER || 'foodme_user',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  };
  config.password = dbPass;
  return config;
}

class DemoInvestigations {
  constructor(logger) {
    this.logger = logger;
    this.manual = this.loadManual();
    this.socketCounter = 0;
    this.lockHelper = null; // { client, pid, windowEndsAt, timer }
    this.lockError = null;
    this.seed = { status: 'idle', customers: 0, indexApplied: false };
  }

  loadManual() {
    try {
      const parsed = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
      if (parsed && (parsed.mode === 'off' || KNOWN_SLUGS.includes(parsed.slug))) return parsed;
    } catch { /* no override yet */ }
    return null;
  }

  saveManual() {
    try {
      if (this.manual) {
        fs.writeFileSync(STATE_FILE, JSON.stringify(this.manual, null, 2));
      } else {
        fs.rmSync(STATE_FILE, { force: true });
      }
    } catch (err) {
      this.logger?.warn({ err }, 'Could not persist demo investigation override; it will last until restart');
    }
  }

  envArmed() {
    if (envTruthy('DEMO_NGINX_502')) return { slug: SLUG_NGINX_502 };
    const raw = process.env.DEMO_DB_SLOW_ORDER_QUERY;
    if (raw) {
      const seconds = Number(raw);
      if (Number.isFinite(seconds) && seconds > 0) return { slug: SLUG_SLOW_ORDER, seconds: clampSeconds(seconds) };
    }
    if (envTruthy('DEMO_DB_LOCK')) return { slug: SLUG_TABLE_LOCKED };
    if (envTruthy('DEMO_DB_BIG_ORDERS')) return { slug: SLUG_SLOW_LOOKUP };
    return null;
  }

  /** Effective state: where the arming comes from, and what is armed. */
  getState() {
    const env = this.envArmed();
    if (env) return { source: 'env', manual: this.manual, armed: this.decorate(env) };
    if (this.manual?.mode === 'off') return { source: 'manual', manual: this.manual, armed: null };
    if (this.manual?.slug) {
      const armed = { slug: this.manual.slug };
      if (this.manual.slug === SLUG_SLOW_ORDER) armed.seconds = clampSeconds(this.manual.seconds);
      return { source: 'manual', manual: this.manual, armed: this.decorate(armed) };
    }
    return { source: 'none', manual: this.manual, armed: null };
  }

  /** Attach live side-effect detail (lock pid, seed progress) to an armed entry. */
  decorate(armed) {
    if (!armed) return armed;
    if (armed.slug === SLUG_TABLE_LOCKED) {
      armed.lockPid = this.lockHelper?.pid ?? null;
      armed.windowEndsAt = this.lockHelper ? new Date(this.lockHelper.windowEndsAt).toISOString() : null;
      if (this.lockError) armed.lockError = this.lockError;
    }
    if (armed.slug === SLUG_SLOW_LOOKUP) {
      armed.seedStatus = this.seed.status;
      armed.seededCustomers = this.seed.customers;
      armed.indexApplied = this.seed.indexApplied;
    }
    return armed;
  }

  /** Seconds of slow query the order path should add (0 = I2 not armed). */
  slowOrderSeconds() {
    const { armed } = this.getState();
    return armed?.slug === SLUG_SLOW_ORDER ? armed.seconds : 0;
  }

  /**
   * I5's intermittency: while armed, every second matching request's
   * socket is destroyed by the server middleware, so nginx - the real
   * proxy in front - mints a genuine 502 and logs that its upstream
   * closed the connection prematurely. Deterministic alternation, so a
   * class sees failures immediately and the 502 share is ~50%.
   */
  shouldDestroySocket() {
    if (this.getState().armed?.slug !== SLUG_NGINX_502) return false;
    this.socketCounter += 1;
    return this.socketCounter % 2 === 0;
  }

  setManual(slug, seconds) {
    this.manual = slug === 'off' ? { mode: 'off' } : { slug, seconds: clampSeconds(seconds) };
    this.saveManual();
    return this.getState();
  }

  clearManual() {
    this.manual = null;
    this.saveManual();
    return this.getState();
  }

  // ------------------------------------------------------------------
  // Side effects (I7 lock helper, I8 seed). Called at boot and after
  // every arm change; safe to call repeatedly.
  // ------------------------------------------------------------------

  async syncSideEffects() {
    const slug = this.getState().armed?.slug;
    try {
      if (slug === SLUG_TABLE_LOCKED) await this.startLockHelper();
      else await this.stopLockHelper();
    } catch (err) {
      this.logger?.warn({ err }, 'Demo investigations: lock helper sync failed');
    }
    if (slug === SLUG_SLOW_LOOKUP) this.ensureSeeded();
    else if (this.seed.status !== 'idle') this.cleanupSeed();
  }

  async startLockHelper() {
    if (this.lockHelper) return;
    const client = new Client(adminClientConfig());
    try {
      await client.connect();
      await client.query('BEGIN');
      await client.query('LOCK TABLE orders IN EXCLUSIVE MODE');
      const { rows } = await client.query('SELECT pg_backend_pid() AS pid');
      const timer = setTimeout(() => { this.stopLockHelper().catch(() => {}); }, LOCK_WINDOW_MS);
      timer.unref?.();
      this.lockHelper = { client, pid: rows[0].pid, windowEndsAt: Date.now() + LOCK_WINDOW_MS, timer };
      this.lockError = null;
      client.on('error', () => { this.lockHelper = null; });
      this.logger?.info({ pid: rows[0].pid }, 'I7 lock helper: orders table locked (EXCLUSIVE) for the demo window');
    } catch (err) {
      this.lockError = 'Lock helper could not connect to Postgres (is the database-backed deployment running?)';
      this.logger?.warn({ err }, 'I7 armed but the lock helper could not start');
      await client.end().catch(() => {});
    }
  }

  async stopLockHelper() {
    const helper = this.lockHelper;
    if (!helper) return;
    this.lockHelper = null;
    clearTimeout(helper.timer);
    try { await helper.client.query('ROLLBACK'); } catch { /* already gone */ }
    try { await helper.client.end(); } catch { /* already gone */ }
    this.logger?.info('I7 lock helper: lock released');
  }

  ensureSeeded() {
    if (this.seed.status === 'seeding' || this.seed.status === 'ready') return;
    this.seed.status = 'seeding';
    (async () => {
      const client = new Client(adminClientConfig());
      try {
        await client.connect();
        const countSeed = async () => {
          const { rows } = await client.query('SELECT count(*)::int AS n FROM customers WHERE phone LIKE $1', [SEED_PHONE_PREFIX + '%']);
          return rows[0].n;
        };
        let have = await countSeed();
        this.seed.customers = have;

        const restaurants = (await client.query('SELECT id FROM restaurants WHERE is_active = true')).rows.map(r => r.id);
        const itemsByRestaurant = new Map();
        for (const rid of restaurants) {
          const { rows } = await client.query('SELECT id, name, price FROM menu_items WHERE restaurant_id = $1 AND is_available = true', [rid]);
          if (rows.length) itemsByRestaurant.set(rid, rows);
        }
        const usable = restaurants.filter(r => itemsByRestaurant.has(r));
        if (!usable.length) throw new Error('No restaurants with menu items to seed against');

        const { rows: ordRows } = await client.query("SELECT count(*)::int AS n FROM orders WHERE order_number LIKE 'SEED-%'");
        let orderSeq = ordRows[0].n;
        let customerSeq = have;

        const BATCH = 1000;
        while (have < SEED_CUSTOMERS) {
          const n = Math.min(BATCH, SEED_CUSTOMERS - have);
          const customerValues = [];
          const customerParams = [];
          for (let i = 0; i < n; i++) {
            customerSeq += 1;
            const base = i * 3;
            customerValues.push(`($${base + 1}, $${base + 2}, $${base + 3})`);
            customerParams.push(
              `Seed Customer ${customerSeq}`,
              `${SEED_PHONE_PREFIX}${String(customerSeq).padStart(5, '0')}`,
              `${customerSeq} Seed Way, Portland, OR`,
            );
          }
          await client.query('BEGIN');
          const inserted = await client.query(
            `INSERT INTO customers (name, phone, address) VALUES ${customerValues.join(',')} RETURNING id`,
            customerParams,
          );
          const orderValues = [];
          const orderParams = [];
          const itemRows = [];
          inserted.rows.forEach((row, ci) => {
            const orderCount = 1 + Math.floor(Math.random() * 3);
            for (let k = 0; k < orderCount; k++) {
              orderSeq += 1;
              const rid = usable[Math.floor(Math.random() * usable.length)];
              const menu = itemsByRestaurant.get(rid);
              const itemCount = 1 + Math.floor(Math.random() * 3);
              let total = 0;
              const chosen = [];
              for (let j = 0; j < itemCount; j++) {
                const item = menu[Math.floor(Math.random() * menu.length)];
                const qty = 1 + Math.floor(Math.random() * 2);
                total += Number(item.price) * qty;
                chosen.push({ orderSeq, item, qty });
              }
              const base = orderValues.length * 6;
              orderValues.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}::timestamptz)`);
              orderParams.push(
                row.id, rid, `SEED-${orderSeq}`,
                Math.random() < 0.9 ? 'delivered' : 'cancelled',
                total.toFixed(2),
                new Date(Date.now() - Math.floor(Math.random() * 730) * 86400000).toISOString(),
              );
              itemRows.push(...chosen);
            }
          });
          const ordersInserted = await client.query(
            `INSERT INTO orders (customer_id, restaurant_id, order_number, status, total_amount, created_at) VALUES ${orderValues.join(',')} RETURNING id, order_number`,
            orderParams,
          );
          const idBySeq = new Map(ordersInserted.rows.map(r => [Number(r.order_number.slice(5)), r.id]));
          const itemValues = [];
          const itemParams = [];
          for (const { orderSeq: seq, item, qty } of itemRows) {
            const base = itemValues.length * 5;
            itemValues.push(`($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5})`);
            itemParams.push(idBySeq.get(seq), item.id, item.name, qty, item.price);
          }
          if (itemValues.length) {
            await client.query(
              `INSERT INTO order_items (order_id, menu_item_id, item_name, quantity, unit_price) VALUES ${itemValues.join(',')}`,
              itemParams,
            );
          }
          await client.query('COMMIT');
          have += n;
          this.seed.customers = have;
        }

        const idx = await client.query('SELECT 1 FROM pg_indexes WHERE indexname = $1', [SEED_INDEX]);
        this.seed.indexApplied = idx.rows.length > 0;
        this.seed.status = 'ready';
        this.logger?.info({ customers: have }, 'I8 seed complete: synthetic order history in place');
      } catch (err) {
        this.seed.status = 'error';
        this.logger?.warn({ err }, 'I8 seeding failed');
        try { await client.query('ROLLBACK'); } catch { /* no transaction open */ }
      } finally {
        await client.end().catch(() => {});
      }
    })();
  }

  /** I8's fix, applied by the instructor from the panel: index the lookup column. */
  async applyIndexFix() {
    if (this.getState().armed?.slug !== SLUG_SLOW_LOOKUP) {
      return { ok: false, error: 'The slow lookup (I8) is not armed' };
    }
    const client = new Client(adminClientConfig());
    try {
      await client.connect();
      await client.query(`CREATE INDEX IF NOT EXISTS ${SEED_INDEX} ON customers (phone)`);
      this.seed.indexApplied = true;
      this.logger?.info('I8 fix applied: index on customers(phone)');
      return { ok: true, state: this.getState() };
    } catch (err) {
      this.logger?.warn({ err }, 'I8 index fix failed');
      return { ok: false, error: 'Could not create the index (is the database-backed deployment running?)' };
    } finally {
      await client.end().catch(() => {});
    }
  }

  cleanupSeed() {
    const previous = this.seed;
    this.seed = { status: 'idle', customers: 0, indexApplied: false };
    (async () => {
      const client = new Client(adminClientConfig());
      try {
        await client.connect();
        await client.query(`DROP INDEX IF EXISTS ${SEED_INDEX}`);
        // orders and order_items cascade away with their customers.
        const { rowCount } = await client.query('DELETE FROM customers WHERE phone LIKE $1', [SEED_PHONE_PREFIX + '%']);
        this.logger?.info({ customers: rowCount, wasStatus: previous.status }, 'I8 seed cleaned up on disarm');
      } catch (err) {
        this.logger?.warn({ err }, 'I8 seed cleanup failed');
      } finally {
        await client.end().catch(() => {});
      }
    })();
  }
}

module.exports = DemoInvestigations;
