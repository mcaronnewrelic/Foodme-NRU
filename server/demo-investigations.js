/**
 * Demo investigations (spec section 11): which investigation, if any, is
 * armed right now. Mirrors demo-failures.js, minus the rotation -
 * investigations are deliberate, never ambient.
 *
 * Priority:
 *   1. Env - DEMO_DB_SLOW_ORDER_QUERY=<seconds> arms "It's not checkout"
 *      (I2): every order runs a pg_sleep of that many seconds inside its
 *      database work, so the order transaction's time sits in one
 *      datastore span.
 *   2. Manual override - POST /api/demo/investigations (the How It Works
 *      instructor controls), persisted to data/demo-investigations.json
 *      so an arm survives restarts. {slug: 'off'} disarms until cleared.
 */
const fs = require('fs');
const path = require('path');

const STATE_FILE = path.join(__dirname, 'data', 'demo-investigations.json');
const KNOWN_SLUGS = ['its-not-checkout'];
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
    const raw = process.env.DEMO_DB_SLOW_ORDER_QUERY;
    if (!raw) return null;
    const seconds = Number(raw);
    if (!Number.isFinite(seconds) || seconds <= 0) return null;
    return { slug: 'its-not-checkout', seconds: clampSeconds(seconds) };
  }

  /** Effective state: where the arming comes from, and what is armed. */
  getState() {
    const env = this.envArmed();
    if (env) return { source: 'env', manual: this.manual, armed: env };
    if (this.manual?.mode === 'off') return { source: 'manual', manual: this.manual, armed: null };
    if (this.manual?.slug) {
      return { source: 'manual', manual: this.manual, armed: { slug: this.manual.slug, seconds: clampSeconds(this.manual.seconds) } };
    }
    return { source: 'none', manual: this.manual, armed: null };
  }

  /** Seconds of slow query the order path should add (0 = not armed). */
  slowOrderSeconds() {
    const { armed } = this.getState();
    return armed?.slug === 'its-not-checkout' ? armed.seconds : 0;
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
