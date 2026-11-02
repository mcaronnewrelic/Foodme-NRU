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
 *      datastore span.
 *   2. Manual override - POST /api/demo/investigations (the How It Works
 *      instructor controls), persisted to data/demo-investigations.json
 *      so an arm survives restarts. {slug: 'off'} disarms until cleared.
 * One investigation armed at a time.
 */
const fs = require('fs');
const path = require('path');

const STATE_FILE = path.join(__dirname, 'data', 'demo-investigations.json');
const SLUG_SLOW_ORDER = 'its-not-checkout';
const SLUG_NGINX_502 = 'the-502-didnt-come-from-the-app';
const SLUG_SINGLE_CONNECTION = 'one-connection-for-the-whole-restaurant';
const KNOWN_SLUGS = [SLUG_SLOW_ORDER, SLUG_NGINX_502, SLUG_SINGLE_CONNECTION];
const DEFAULT_SECONDS = 3;
const MAX_SECONDS = 10;

function clampSeconds(value) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_SECONDS;
  return Math.min(Math.max(Math.round(n), 1), MAX_SECONDS);
}

class DemoInvestigations {
  constructor(logger) {
    this.logger = logger;
    this.manual = this.loadManual();
    this.socketCounter = 0;
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
    const nginx502 = process.env.DEMO_NGINX_502;
    if (nginx502 && nginx502 !== '0' && nginx502 !== 'off') {
      return { slug: SLUG_NGINX_502 };
    }
    const raw = process.env.DEMO_DB_SLOW_ORDER_QUERY;
    if (!raw) return null;
    const seconds = Number(raw);
    if (!Number.isFinite(seconds) || seconds <= 0) return null;
    return { slug: SLUG_SLOW_ORDER, seconds: clampSeconds(seconds) };
  }

  /** Effective state: where the arming comes from, and what is armed. */
  getState() {
    const env = this.envArmed();
    if (env) return { source: 'env', manual: this.manual, armed: env };
    if (this.manual?.mode === 'off') return { source: 'manual', manual: this.manual, armed: null };
    if (this.manual?.slug) {
      const armed = { slug: this.manual.slug };
      if (this.manual.slug === SLUG_SLOW_ORDER) armed.seconds = clampSeconds(this.manual.seconds);
      return { source: 'manual', manual: this.manual, armed };
    }
    return { source: 'none', manual: this.manual, armed: null };
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
}

module.exports = DemoInvestigations;
