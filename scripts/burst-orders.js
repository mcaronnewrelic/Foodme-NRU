#!/usr/bin/env node
/**
 * Burst orders - the load arm for investigation I6, "One connection for
 * the whole restaurant" (spec section 11.2).
 *
 * Places concurrent orders over HTTP as a simulated visitor carrying a
 * SIM- demoCode (so the traffic is excludable from cohort data, per the
 * SIM- convention), and arms/disarms the investigation around the burst
 * via /api/demo/investigations.
 *
 * Why it works: server/database.js runs every query through ONE pg
 * Client, so concurrent orders serialize. Response times climb while
 * Postgres itself stays idle and active_connections pins at 1 - the
 * exact evidence I6's checkpoints interrogate. Only meaningful against
 * the Postgres-backed deployment (staging); the JSON-file dev mode has
 * no database to queue on.
 *
 * Usage:
 *   node scripts/burst-orders.js [baseUrl] [--seconds 240]
 *        [--concurrency 16] [--items 8] [--code SIM-BST1] [--no-arm]
 */
'use strict';

const args = process.argv.slice(2);
let baseUrl = (args.find(a => !a.startsWith('--')) || 'http://staging-foodme-alb-327574077.us-west-2.elb.amazonaws.com').replace(/\/$/, '');
if (!/^https?:\/\//.test(baseUrl)) baseUrl = 'http://' + baseUrl;
function flag(name, fallback) {
  const i = args.indexOf('--' + name);
  return i >= 0 ? args[i + 1] : fallback;
}
const SECONDS = parseInt(flag('seconds', '240'), 10);
const CONCURRENCY = parseInt(flag('concurrency', '16'), 10);
const ITEMS = parseInt(flag('items', '8'), 10);
const CODE = flag('code', 'SIM-BST1');
const ARM = !args.includes('--no-arm');
const SLUG = 'one-connection-for-the-whole-restaurant';

// Mirror nameToSlug() in server/url-utils.js exactly: punctuation is
// removed (not dashed) and spaces become underscores -
// "Esther's German Saloon" -> "esthers_german_saloon".
function nameToSlug(name) {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
}

let placed = 0;
let failed = 0;
let latencies = [];
let stopping = false;

async function api(path, options) {
  const res = await fetch(baseUrl + path, options);
  if (!res.ok) throw new Error(`${path} -> HTTP ${res.status}`);
  return res.json();
}

async function arm() {
  if (!ARM) return;
  await api('/api/demo/investigations', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ slug: SLUG }),
  });
  console.log(`Armed investigation "${SLUG}" (clears when the burst ends).`);
}

async function disarm() {
  if (!ARM) return;
  try {
    await fetch(baseUrl + '/api/demo/investigations', { method: 'DELETE' });
    console.log('Investigation disarmed (manual override cleared).');
  } catch { /* the instructor panel can disarm too */ }
}

async function worker(restaurant, menuItems, deadline) {
  const items = menuItems.slice(0, ITEMS);
  if (items.length === 0) return;
  while (!stopping && Date.now() < deadline) {
    const orderItems = items.map(it => ({ name: it.name, price: it.price, qty: 1 }));
    const total = orderItems.reduce((sum, it) => sum + it.price, 0);
    const order = {
      deliverTo: { name: CODE, phone: '(503) 555-0199', address: '1 Burst Way, Portland, OR 97205' },
      restaurant: { id: restaurant.id, name: restaurant.name },
      items: orderItems,
      demoCode: CODE,
      total,
      timestamp: new Date().toISOString(),
    };
    const started = Date.now();
    try {
      await api('/api/order', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(order),
      });
      placed += 1;
      latencies.push(Date.now() - started);
    } catch {
      failed += 1;
    }
    await new Promise(r => setTimeout(r, Math.random() * 150));
  }
}

async function main() {
  console.log(`Burst: ${CONCURRENCY} concurrent order placers x ${SECONDS}s against ${baseUrl} as ${CODE}`);
  const restaurants = await api('/api/restaurant');
  if (!Array.isArray(restaurants) || restaurants.length === 0) throw new Error('No restaurants returned');

  const menus = new Map();
  for (const restaurant of restaurants.slice(0, CONCURRENCY)) {
    const slug = encodeURIComponent(nameToSlug(restaurant.name));
    try {
      const full = await api(`/api/restaurant/by-name/${slug}`);
      menus.set(restaurant.id, full.menuItems || full.menu_items || []);
    } catch (err) {
      console.warn(`Skipping "${restaurant.name}": ${err.message}`);
    }
  }
  if (menus.size === 0) throw new Error('No restaurant menus could be loaded');

  await arm();
  const deadline = Date.now() + SECONDS * 1000;
  const reporter = setInterval(() => {
    const sorted = [...latencies].sort((a, b) => a - b);
    const avg = sorted.length ? Math.round(sorted.reduce((a, b) => a + b, 0) / sorted.length) : 0;
    const p95 = sorted.length ? sorted[Math.floor(sorted.length * 0.95)] : 0;
    console.log(`  placed=${placed} failed=${failed} avgOrderMs=${avg} p95OrderMs=${p95}`);
    latencies = [];
  }, 15000);

  const workers = [];
  const pool = restaurants.slice(0, CONCURRENCY).filter(r => (menus.get(r.id) || []).length > 0);
  for (let i = 0; i < CONCURRENCY; i++) {
    const restaurant = pool[i % pool.length];
    workers.push(worker(restaurant, menus.get(restaurant.id) || [], deadline));
  }
  await Promise.all(workers);
  clearInterval(reporter);
  console.log(`Done: placed=${placed} failed=${failed}`);
  await disarm();
}

process.on('SIGINT', async () => {
  stopping = true;
  await disarm();
  process.exit(0);
});

main().catch(async err => {
  console.error('Burst failed:', err.message);
  await disarm();
  process.exit(1);
});
