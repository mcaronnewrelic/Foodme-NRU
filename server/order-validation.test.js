const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const vm = require('node:vm');

function createCheckout(databaseMode) {
  const routes = new Map();
  const restaurant = { id: 'restaurant-a', menuItems: [{ id: 'item-a', name: 'Soup' }] };
  const calls = { metrics: 0, orders: 0 };
  const app = {
    locals: {}, use() {}, get() {}, put() {}, delete() {}, listen() {},
    post(url, ...handlers) { routes.set(url, handlers.at(-1)); }
  };
  const logger = { info() {}, debug() {}, warn() {}, error() {}, fatal() {} };
  class Database {
    async isAvailable() { return true; }
    async getRestaurantById(id) { return id === restaurant.id ? restaurant : null; }
    async createOrder() { calls.orders++; return { orderId: 123 }; }
  }
  class Memory {
    getById(id) { return id === restaurant.id ? restaurant : null; }
  }
  class Demo {
    async syncSideEffects() {}
    getFailing() { return {}; }
    slowOrderSeconds() { return 0; }
  }
  const dependencies = {
    newrelic: {
      addCustomAttributes() {}, setUserID() {}, recordMetric() {}, recordCustomEvent() {},
      incrementMetric() { calls.metrics++; }
    },
    pino: () => logger,
    express: Object.assign(() => app, { static: () => () => {} }),
    morgan: () => () => {},
    'body-parser': { json: () => () => {} },
    'express-handlebars': {}, path,
    fs: { existsSync: () => false, readFile() {} },
    open: { default() {} },
    './model': {}, './storage': { Memory }, './database': Database,
    './demo-failures': Demo, './demo-investigations': Demo,
    './order-status-worker': class {}, axios: {}, './url-utils': { nameToSlug: value => value }
  };
  const context = {
    exports: {}, __dirname,
    require(name) {
      assert.ok(Object.hasOwn(dependencies, name), `Unexpected dependency: ${name}`);
      return dependencies[name];
    },
    process: { env: databaseMode ? { NODE_ENV: 'production' } : {}, cwd: () => __dirname, on() {} }
  };
  vm.runInNewContext(readFileSync(path.join(__dirname, 'index.js'), 'utf8'), context);
  context.exports.start(0, '', '', '');

  return async order => {
    const response = { statusCode: 200, status(code) { this.statusCode = code; return this; },
      json(body) { this.body = body; return this; }, send(body) { this.body = body; return this; } };
    await routes.get('/api/order')({ body: order, requestId: 'test' }, response, error => { throw error; });
    return { response, calls };
  };
}

for (const databaseMode of [false, true]) {
  const mode = databaseMode ? 'database' : 'memory';
  const order = items => ({ restaurant: { id: 'restaurant-a' }, items });
  const ownItem = { id: 'item-a', name: 'Soup', price: 5, qty: 1 };

  test(`${mode}: rejects foreign item IDs before order side effects`, async () => {
    const { response, calls } = await createCheckout(databaseMode)(order([ownItem, { ...ownItem, id: 'item-b' }]));
    assert.equal(response.statusCode, 400);
    assert.equal(calls.metrics, 0);
    assert.equal(calls.orders, 0);
  });

  test(`${mode}: rejects foreign menu_item_id even with a valid item id`, async () => {
    const { response } = await createCheckout(databaseMode)(order([{ ...ownItem, menu_item_id: 'item-b' }]));
    assert.equal(response.statusCode, 400);
  });

  test(`${mode}: rejects mixed legacy item names`, async () => {
    const { response } = await createCheckout(databaseMode)(order([{ name: 'Soup' }, { name: 'Foreign pizza' }]));
    assert.equal(response.statusCode, 400);
  });

  test(`${mode}: rejects conflicting explicit restaurant ownership`, async () => {
    const { response } = await createCheckout(databaseMode)(order([{ ...ownItem, restaurant_id: 'restaurant-b' }]));
    assert.equal(response.statusCode, 400);
  });

  test(`${mode}: accepts a single restaurant's items with IDs or legacy names`, async () => {
    for (const item of [ownItem, { name: 'Soup', price: 5, qty: 2 }]) {
      const { response, calls } = await createCheckout(databaseMode)(order([item]));
      assert.equal(response.statusCode, 201);
      assert.equal(calls.metrics, 1);
      assert.equal(calls.orders, databaseMode ? 1 : 0);
    }
  });

  test(`${mode}: rejects malformed, empty, and unknown restaurant orders`, async () => {
    for (const invalid of [undefined, {}, order([]), order([null]), order('invalid'),
      { restaurant: { id: 'unknown' }, items: [ownItem] }]) {
      const { response } = await createCheckout(databaseMode)(invalid);
      assert.equal(response.statusCode, 400);
    }
  });
}