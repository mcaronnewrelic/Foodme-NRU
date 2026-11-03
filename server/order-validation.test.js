const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");
const vm = require("node:vm");
const { nameToSlug } = require("./url-utils");

function createCheckout(
  databaseMode,
  { failOrder = false, failing = {} } = {},
) {
  const routes = new Map();
  const restaurant = {
    id: "restaurant-a",
    name: "Restaurant A",
    menuItems: [{ id: "item-a", name: "Soup" }],
  };
  const calls = {
    metrics: 0,
    orders: 0,
    events: [],
    metricValues: [],
    attributes: {},
    sequence: [],
  };
  const app = {
    locals: {},
    use() {},
    get() {},
    put() {},
    delete() {},
    listen() {},
    post(url, ...handlers) {
      routes.set(url, handlers.at(-1));
    },
  };
  const logger = { info() {}, debug() {}, warn() {}, error() {}, fatal() {} };
  class Database {
    async isAvailable() {
      return true;
    }
    async getRestaurantById(id) {
      return id === restaurant.id ? restaurant : null;
    }
    async createOrder() {
      calls.orders++;
      calls.sequence.push("createOrder");
      if (failOrder) throw new Error("Database write failed");
      return { orderId: 123 };
    }
  }
  class Memory {
    getById(id) {
      return id === restaurant.id ? restaurant : null;
    }
  }
  class Demo {
    async syncSideEffects() {}
    getFailing() {
      return failing;
    }
    slowOrderSeconds() {
      return 0;
    }
  }
  const dependencies = {
    newrelic: {
      addCustomAttributes(attributes) {
        Object.assign(calls.attributes, attributes);
      },
      setUserID() {},
      recordMetric(name, value) {
        calls.metrics++;
        calls.metricValues.push({ name, value });
        calls.sequence.push("metric");
      },
      recordCustomEvent(name, attributes) {
        calls.events.push({ name, attributes });
        calls.sequence.push("event");
      },
      incrementMetric() {
        calls.metrics++;
      },
    },
    pino: () => logger,
    express: Object.assign(() => app, { static: () => () => {} }),
    morgan: () => () => {},
    "body-parser": { json: () => () => {} },
    "express-handlebars": {},
    path,
    "node:crypto": require("node:crypto"),
    fs: { existsSync: () => false, readFile() {} },
    open: { default() {} },
    "./model": {},
    "./storage": { Memory },
    "./database": Database,
    "./demo-failures": Demo,
    "./demo-investigations": Demo,
    "./order-status-worker": class {},
    axios: {},
    "./url-utils": { nameToSlug },
  };
  const context = {
    exports: {},
    __dirname,
    require(name) {
      assert.ok(
        Object.hasOwn(dependencies, name),
        `Unexpected dependency: ${name}`,
      );
      return dependencies[name];
    },
    process: {
      env: databaseMode ? { NODE_ENV: "production" } : {},
      cwd: () => __dirname,
      on() {},
    },
  };
  vm.runInNewContext(
    readFileSync(path.join(__dirname, "index.js"), "utf8"),
    context,
  );
  context.exports.start(0, "", "", "");

  return async (order) => {
    const response = {
      statusCode: 200,
      status(code) {
        this.statusCode = code;
        return this;
      },
      json(body) {
        this.body = body;
        return this;
      },
      send(body) {
        this.body = body;
        return this;
      },
    };
    await routes.get("/api/order")(
      { body: order, requestId: "test" },
      response,
      (error) => {
        response.error = error;
      },
    );
    return { response, calls };
  };
}

for (const databaseMode of [false, true]) {
  const mode = databaseMode ? "database" : "memory";
  const order = (items) => ({ restaurant: { id: "restaurant-a" }, items });
  const ownItem = { id: "item-a", name: "Soup", price: 5, qty: 1 };

  test(`${mode}: rejects foreign item IDs before order side effects`, async () => {
    const { response, calls } = await createCheckout(databaseMode)(
      order([ownItem, { ...ownItem, id: "item-b" }]),
    );
    assert.equal(response.statusCode, 400);
    assert.equal(calls.metrics, 0);
    assert.equal(calls.orders, 0);
  });

  test(`${mode}: rejects foreign menu_item_id even with a valid item id`, async () => {
    const { response } = await createCheckout(databaseMode)(
      order([{ ...ownItem, menu_item_id: "item-b" }]),
    );
    assert.equal(response.statusCode, 400);
  });

  test(`${mode}: rejects mixed legacy item names`, async () => {
    const { response } = await createCheckout(databaseMode)(
      order([{ name: "Soup" }, { name: "Foreign pizza" }]),
    );
    assert.equal(response.statusCode, 400);
  });

  test(`${mode}: rejects conflicting explicit restaurant ownership`, async () => {
    const { response } = await createCheckout(databaseMode)(
      order([{ ...ownItem, restaurant_id: "restaurant-b" }]),
    );
    assert.equal(response.statusCode, 400);
  });

  test(`${mode}: accepts a single restaurant's items with IDs or legacy names`, async () => {
    for (const item of [ownItem, { name: "Soup", price: 5, qty: 2 }]) {
      const { response, calls } = await createCheckout(databaseMode)(
        order([item]),
      );
      assert.equal(response.statusCode, 201);
      assert.equal(calls.metrics, 2);
      assert.equal(calls.orders, databaseMode ? 1 : 0);
    }
  });

  test(`${mode}: rejects malformed, empty, and unknown restaurant orders`, async () => {
    for (const invalid of [
      undefined,
      {},
      order([]),
      order([null]),
      order("invalid"),
      { restaurant: { id: "unknown" }, items: [ownItem] },
    ]) {
      const { response } = await createCheckout(databaseMode)(invalid);
      assert.equal(response.statusCode, 400);
    }
  });

  test(`${mode}: records item details and bounded metrics using the accepted order ID`, async () => {
    const { response, calls } = await createCheckout(databaseMode)({
      ...order([ownItem, { ...ownItem, qty: 3, price: 5.95 }]),
      deliverTo: { name: "OU-TEST" },
      demoCode: "OU-TEST",
    });
    assert.equal(response.statusCode, 201);
    assert.equal(calls.attributes.orderId, response.body.orderId);
    assert.equal(calls.attributes.customer, "OU-TEST");
    assert.equal(calls.attributes.restaurant, "Restaurant A");
    assert.equal(calls.attributes.itemCount, 4);
    assert.equal(calls.attributes.orderTotal, 22.85);
    assert.equal(calls.events.length, 2);
    for (const [index, event] of calls.events.entries()) {
      assert.equal(event.name, "ItemsOrdered");
      assert.equal(event.attributes.orderId, response.body.orderId);
      assert.equal(event.attributes.itemName, "Soup");
      assert.equal(event.attributes.itemCount, index === 0 ? 1 : 3);
      assert.equal(event.attributes.customer, undefined);
      assert.equal(event.attributes.restaurant, undefined);
      assert.equal(event.attributes.demoCode, "OU-TEST");
    }
    assert.deepEqual(calls.metricValues, [
      { name: "total", value: 22.85 },
      { name: "restaurant_a/total", value: 22.85 },
    ]);
    if (databaseMode) assert.equal(calls.sequence[0], "createOrder");
  });
}

test("database: a failed write emits no accepted-order events or metrics", async () => {
  const { response, calls } = await createCheckout(true, { failOrder: true })({
    restaurant: { id: "restaurant-a" },
    items: [{ id: "item-a", name: "Soup", price: 5, qty: 1 }],
  });
  assert.equal(response.error?.message, "Database write failed");
  assert.equal(response.body, undefined);
  assert.equal(calls.metrics, 0);
  assert.equal(calls.events.length, 0);
  assert.equal(calls.attributes.orderId, undefined);
});

test("planned failures keep business attributes but emit no sales telemetry", async () => {
  const { response, calls } = await createCheckout(true, {
    failing: { orderItem: "soup" },
  })({
    restaurant: { id: "restaurant-a" },
    items: [{ id: "item-a", name: "Soup", price: 5, qty: 1 }],
  });
  assert.match(response.error?.message, /Inventory check failed/);
  assert.equal(calls.attributes.restaurant, "Restaurant A");
  assert.equal(calls.attributes.itemCount, 1);
  assert.equal(calls.metrics, 0);
  assert.equal(calls.events.length, 0);
});

test("memory: accepted orders receive distinct server-generated IDs", async () => {
  const checkout = createCheckout(false);
  const order = {
    orderId: "client-id",
    restaurant: { id: "restaurant-a" },
    items: [{ id: "item-a", name: "Soup", price: 5, qty: 1 }],
  };
  const first = await checkout(order);
  const second = await checkout(order);
  assert.match(first.response.body.orderId, /^[0-9a-f-]{36}$/);
  assert.notEqual(first.response.body.orderId, second.response.body.orderId);
  assert.notEqual(first.response.body.orderId, order.orderId);
});
