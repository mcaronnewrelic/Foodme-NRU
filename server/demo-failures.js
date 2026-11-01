/**
 * Demo failure scenarios: which restaurant / order target currently fails,
 * decided dynamically instead of by server environment alone.
 *
 * Priority:
 *   1. Environment (DEMO_FAILING_RESTAURANT / DEMO_FAILING_ORDER_RESTAURANT /
 *      DEMO_FAILING_ORDER_ITEM) — the original switches; if any is set it
 *      wins outright, so an operator can always force a scenario.
 *   2. Manual override — set through POST /api/demo/failures (the How It
 *      Works instructor panel), persisted to data/demo-failures.json so it
 *      survives restarts. Can arm one scenario, or "off" (nothing fails).
 *   3. Weekly rotation — a deterministic pick from the seed data, derived
 *      from the ISO week, so the failing target changes every week with no
 *      one touching anything, and every instance agrees on the pick.
 *      Disable with DEMO_FAILURE_ROTATION=off.
 *
 * One scenario is armed at a time in manual/rotation modes. Targets are
 * stored and compared as slugs (see url-utils.nameToSlug); the state also
 * carries the display name so the site can show it in its behind-the-scenes
 * content instead of making learners guess.
 *
 * This is deliberately unauthenticated: it is a teaching demo, the worst
 * case is a different demo failure than expected, and every change is
 * logged. Do not reuse this pattern for anything that matters.
 */
const fs = require('fs');
const path = require('path');
const { nameToSlug } = require('./url-utils');

const STATE_FILE = path.join(__dirname, 'data', 'demo-failures.json');
const RESTAURANTS_FILE = path.join(__dirname, 'data', 'restaurants.json');

const KINDS = ['restaurant', 'order-restaurant', 'order-item'];
const KIND_TO_FIELD = {
  'restaurant': 'restaurant',
  'order-restaurant': 'orderRestaurant',
  'order-item': 'orderItem'
};

function loadCandidates() {
  try {
    const restaurants = JSON.parse(fs.readFileSync(RESTAURANTS_FILE, 'utf8'));
    const restaurantNames = restaurants.map(r => r.name).filter(Boolean);
    const itemNames = [...new Set(
      restaurants.flatMap(r => (r.menuItems || []).map(m => m.name)).filter(Boolean)
    )];
    return { restaurantNames, itemNames };
  } catch {
    return { restaurantNames: [], itemNames: [] };
  }
}

function isoWeekKey(date = new Date()) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day); // nearest Thursday decides the ISO year
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

function hashString(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

class DemoFailures {
  constructor(logger) {
    this.logger = logger;
    this.candidates = loadCandidates();
    this.manual = this.loadManual();
    this.rotationCache = { week: null, scenario: null };
  }

  loadManual() {
    try {
      const parsed = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
      if (parsed && (parsed.mode === 'off' || KINDS.includes(parsed.kind))) return parsed;
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
      this.logger?.warn({ err }, 'Could not persist demo failure override; it will last until restart');
    }
  }

  envOverride() {
    const restaurant = process.env.DEMO_FAILING_RESTAURANT || null;
    const orderRestaurant = process.env.DEMO_FAILING_ORDER_RESTAURANT || null;
    const orderItem = process.env.DEMO_FAILING_ORDER_ITEM || null;
    if (!restaurant && !orderRestaurant && !orderItem) return null;
    return { restaurant, orderRestaurant, orderItem };
  }

  rotation() {
    const week = isoWeekKey();
    if (this.rotationCache.week === week) return this.rotationCache.scenario;
    let scenario = null;
    if (process.env.DEMO_FAILURE_ROTATION !== 'off') {
      const h = hashString(`foodme-demo-${week}`);
      const kind = KINDS[h % KINDS.length];
      const names = kind === 'order-item' ? this.candidates.itemNames : this.candidates.restaurantNames;
      if (names.length > 0) {
        const targetName = names[(h >>> 3) % names.length];
        scenario = { kind, target: nameToSlug(targetName), targetName };
      }
    }
    this.rotationCache = { week, scenario };
    return scenario;
  }

  nameForSlug(kind, slug) {
    const names = kind === 'order-item' ? this.candidates.itemNames : this.candidates.restaurantNames;
    return names.find(n => nameToSlug(n) === slug) || slug;
  }

  /** Effective state: where the scenario comes from, and what is armed. */
  getState() {
    const week = isoWeekKey();
    const env = this.envOverride();
    if (env) {
      const field = env.restaurant ? 'restaurant' : env.orderRestaurant ? 'orderRestaurant' : 'orderItem';
      const kind = Object.keys(KIND_TO_FIELD).find(k => KIND_TO_FIELD[k] === field);
      const target = env[field];
      return {
        source: 'env', week, manual: this.manual,
        armed: { kind, target, targetName: this.nameForSlug(kind, target) }
      };
    }
    if (this.manual?.mode === 'off') {
      return { source: 'manual', week, manual: this.manual, armed: null };
    }
    if (this.manual?.mode === 'scenario') {
      return {
        source: 'manual', week, manual: this.manual,
        armed: { kind: this.manual.kind, target: this.manual.target, targetName: this.manual.targetName }
      };
    }
    const scenario = this.rotation();
    return { source: scenario ? 'rotation' : 'none', week, manual: this.manual, armed: scenario };
  }

  /** Slugs for the three failure checks; null means that check is off. */
  getFailing() {
    const env = this.envOverride();
    if (env) return env;
    const failing = { restaurant: null, orderRestaurant: null, orderItem: null };
    const { armed } = this.getState();
    if (armed) failing[KIND_TO_FIELD[armed.kind]] = armed.target;
    return failing;
  }

  /** Arm one scenario (target may be a display name or a slug), or 'off'. */
  setManual(kind, target) {
    if (kind === 'off') {
      this.manual = { mode: 'off' };
    } else {
      this.manual = { mode: 'scenario', kind, target: nameToSlug(target), targetName: this.nameForSlug(kind, nameToSlug(target)) };
    }
    this.saveManual();
    return this.getState();
  }

  clearManual() {
    this.manual = null;
    this.saveManual();
    return this.getState();
  }
}

module.exports = DemoFailures;
