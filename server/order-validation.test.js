const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");
const vm = require("node:vm");
const http = require("node:http");
const { once } = require("node:events");
const { nameToSlug } = require("./url-utils");

function createCheckout(
  databaseMode,
  { failOrder = false, failing = {}, realHttp = false } = {},
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
    logs: [],
    databaseChecks: 0,
    manualChanges: [],
    clearedOverrides: 0,
    sideEffects: 0,
  };
  const express = realHttp ? require("express") : null;
  let app = realHttp
    ? null
    : {
        locals: {},
        use(prefix, router) {
          if (typeof prefix !== "string" || !router?.routes) return;
          for (const [route, handler] of router.routes) {
            routes.set(prefix + (route === "/" ? "" : route), handler);
          }
        },
        get(url, ...handlers) {
          routes.set(url, handlers.at(-1));
        },
        put() {},
        delete() {},
        listen() {
          assert.fail("createApp must not start a listener");
        },
        post(url, ...handlers) {
          routes.set(url, handlers.at(-1));
        },
      };
  const logger = {
    info(fields, message) {
      calls.logs.push({ fields, message });
    },
    debug() {},
    warn() {},
    error() {},
    fatal() {},
  };
  class Database {
    async isAvailable() {
      calls.databaseChecks++;
      return true;
    }
    async getRestaurantById(id) {
      return id === restaurant.id ? restaurant : null;
    }
    async getRestaurantByName(name) {
      return name === nameToSlug(restaurant.name) ? restaurant : null;
    }
    async getOrdersByCustomerPhone(phone) {
      return [{ orderId: 123, customer_phone: phone }];
    }
    async getOrderById(id) {
      return id === "123" ? { orderId: 123, customer_name: "OU-TEST" } : null;
    }
    async createOrder() {
      calls.orders++;
      calls.sequence.push("createOrder");
      if (failOrder) throw new Error("Database write failed");
      return { orderId: 123 };
    }
  }
  class Memory {
    getAll() {
      return [restaurant];
    }
    getById(id) {
      return id === restaurant.id ? restaurant : null;
    }
  }
  class Demo {
    syncSideEffects() {
      assert.ok(
        calls.manualChanges.length || calls.clearedOverrides,
        "createApp must not synchronize investigation side effects",
      );
      calls.sideEffects++;
    }
    getState() {
      return { armed: null, source: "test" };
    }
    setManual(...argumentsList) {
      calls.manualChanges.push(argumentsList);
      return this.getState();
    }
    clearManual() {
      calls.clearedOverrides++;
      return this.getState();
    }
    async applyIndexFix() {
      return { ok: false };
    }
    shouldDestroySocket() {
      return false;
    }
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
    pino: () => ({ info() {}, debug() {}, warn() {}, error() {}, fatal() {} }),
    express: realHttp
      ? express
      : Object.assign(() => app, {
          static: () => () => {},
          Router() {
            const routerRoutes = new Map();
            return {
              routes: routerRoutes,
              use() {},
              get(route, ...handlers) {
                routerRoutes.set(route, handlers.at(-1));
              },
              post(route, ...handlers) {
                routerRoutes.set(route, handlers.at(-1));
              },
              put(route, ...handlers) {
                routerRoutes.set(route, handlers.at(-1));
              },
              delete(route, ...handlers) {
                routerRoutes.set(route, handlers.at(-1));
              },
            };
          },
        }),
    "body-parser": realHttp ? require("body-parser") : { json: () => () => {} },
    "express-handlebars": {},
    path,
    "node:crypto": require("node:crypto"),
    fs: {
      existsSync: () => false,
      readFile() {
        assert.fail("createApp must not load startup data");
      },
    },
    open: {
      default() {
        assert.fail("createApp must not open a browser");
      },
    },
    "./model": {},
    "./storage": { Memory },
    "./database": Database,
    "./dashboard-links": require("./dashboard-links"),
    "./demo-failures": Demo,
    "./demo-investigations": Demo,
    "./order-status-worker": class {
      constructor() {
        assert.fail("createApp must not construct a status worker");
      }
    },
    axios: {
      async get() {
        const error = new Error("test timeout");
        error.code = "ECONNABORTED";
        throw error;
      },
    },
    "./url-utils": { nameToSlug },
  };
  const context = {
    exports: {},
    __dirname,
    process: {
      env: databaseMode ? { NODE_ENV: "production" } : {},
      cwd: () => __dirname,
      on() {
        assert.fail("createApp must not register process handlers");
      },
      uptime: process.uptime,
      memoryUsage: process.memoryUsage,
      cpuUsage: process.cpuUsage,
      pid: process.pid,
      version: process.version,
    },
  };
  function loadModule(filePath) {
    const module = { exports: {} };
    vm.runInNewContext(readFileSync(filePath, "utf8"), {
      ...context,
      module,
      exports: module.exports,
      __dirname: path.dirname(filePath),
      setTimeout,
      Buffer,
      console,
      require(name) {
        if (name.startsWith(".")) {
          const resolved = path.resolve(path.dirname(filePath), name);
          if (
            ["routes", "middleware"].some((dir) =>
              resolved.startsWith(path.join(__dirname, dir) + path.sep),
            )
          ) {
            return loadModule(resolved + ".js");
          }
          name = "./" + path.relative(__dirname, resolved);
        }
        assert.ok(
          Object.hasOwn(dependencies, name),
          `Unexpected dependency: ${name}`,
        );
        return dependencies[name];
      },
    });
    return module.exports;
  }
  context.exports = loadModule(path.join(__dirname, "index.js"));
  const appDependencies = {
    logger,
    newrelic: dependencies.newrelic,
    storage: new Memory(),
    dbService: new Database(),
    demoFailures: new Demo(),
    demoInvestigations: new Demo(),
    useDatabase: databaseMode,
  };
  app = context.exports.createApp(appDependencies);
  assert.equal(
    calls.databaseChecks,
    0,
    "createApp must not connect to the database",
  );

  const checkout = async (order) => {
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
  checkout.dashboard = async (query) => {
    const response = {
      headers: {},
      statusCode: 200,
      setHeader(name, value) {
        this.headers[name] = value;
      },
      status(code) {
        this.statusCode = code;
        return this;
      },
      json(body) {
        this.body = body;
        return this;
      },
      redirect(url) {
        this.statusCode = 302;
        this.url = url;
      },
    };
    await routes.get("/api/dashboard")({ query }, response);
    return response;
  };
  checkout.app = app;
  checkout.dependencies = appDependencies;
  checkout.calls = calls;
  checkout.createApp = context.exports.createApp;
  return checkout;
}

async function serveApp(app, context) {
  const server = http.createServer(app);
  context.after(
    () =>
      new Promise((resolve, reject) => {
        server.close((error) => (error ? reject(error) : resolve()));
        server.closeAllConnections();
      }),
  );
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  return `http://127.0.0.1:${server.address().port}`;
}

test("createApp returns Express without starting process or data-source lifecycle", () => {
  const checkout = createCheckout(true, { realHttp: true });
  assert.equal(typeof checkout.app, "function");
  assert.equal(checkout.app.locals.newrelic, checkout.dependencies.newrelic);
  assert.equal(checkout.calls.databaseChecks, 0);
});

test("apps from the same factory keep independent storage and database selection", async (context) => {
  const checkout = createCheckout(false, { realHttp: true });
  const firstUrl = await serveApp(checkout.app, context);
  const secondApp = checkout.createApp({
    ...checkout.dependencies,
    useDatabase: true,
    dbService: {
      async getAllRestaurants() {
        return [{ id: "restaurant-b", name: "Restaurant B" }];
      },
    },
  });
  const secondUrl = await serveApp(secondApp, context);
  const first = await fetch(`${firstUrl}/api/restaurant`);
  const second = await fetch(`${secondUrl}/api/restaurant`);
  assert.equal(first.status, 200);
  assert.equal(second.status, 200);
  assert.equal((await first.json())[0].id, "restaurant-a");
  assert.equal((await second.json())[0].id, "restaurant-b");
});

test("Express checkout parses JSON and preserves telemetry and Pino request logs", async (context) => {
  const checkout = createCheckout(false, { realHttp: true });
  const url = await serveApp(checkout.app, context);
  const response = await fetch(`${url}/api/order`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "test-secret",
    },
    body: JSON.stringify({
      restaurant: { id: "restaurant-a", name: "Restaurant A" },
      items: [{ id: "item-a", name: "Soup", price: 5, qty: 2 }],
      deliverTo: { name: "OU-TEST", phone: "555-0100" },
    }),
  });
  assert.equal(response.status, 201);
  const body = await response.json();
  assert.equal(typeof body.orderId, "string");
  assert.equal(body.requestId, response.headers.get("X-Request-ID"));
  assert.equal(checkout.calls.events[0].attributes.orderId, body.orderId);
  assert.equal(checkout.calls.attributes.requestId, body.requestId);
  const incoming = checkout.calls.logs.find(
    (log) => log.message === "Incoming request",
  );
  const completed = checkout.calls.logs.find(
    (log) => log.message === "Request completed",
  );
  assert.equal(incoming.fields.headers.authorization, "[REDACTED]");
  assert.equal(incoming.fields.requestId, body.requestId);
  assert.equal(completed.fields.statusCode, 201);
  assert.equal(completed.fields.requestId, body.requestId);
  assert.equal(completed.fields.url, "/api/order");
});

test("Express error middleware remains after routes and returns correlation headers", async (context) => {
  const checkout = createCheckout(false, { realHttp: true });
  const url = await serveApp(checkout.app, context);
  const response = await fetch(`${url}/simulate/error/sync`);
  assert.equal(response.status, 500);
  const body = await response.json();
  assert.equal(body.status, "error");
  assert.equal(body.errorId, response.headers.get("X-Error-ID"));
  assert.ok(response.headers.get("X-Request-ID"));
});

test("four routers contain every extracted route and HTTP method", () => {
  const { app } = createCheckout(false, { realHttp: true });
  const routers = app.router.stack.filter((layer) => layer.name === "router");
  const expected = [
    [
      "get /error/sync",
      "get /error/async-unhandled",
      "get /cpu-hog",
      "get /memory-leak",
      "get /memory-leak/clear",
      "get /slow-response",
      "get /external-api-timeout",
      "get /uncaught-exception",
    ],
    [
      "get /nr-config",
      "get /dashboard",
      "get /demo/failures",
      "post /demo/failures",
      "delete /demo/failures",
      "get /demo/investigations",
      "post /demo/investigations",
      "delete /demo/investigations",
    ],
    [
      "get /",
      "post /",
      "get /:id",
      "get /by-name/:name",
      "put /:id",
      "delete /:id",
    ],
    ["post /order", "get /orders/customer/phone/:phone", "get /orders/:id"],
  ];
  assert.equal(routers.length, expected.length);
  routers.forEach((layer, index) => {
    const actual = layer.handle.stack
      .filter((entry) => entry.route)
      .flatMap(({ route }) =>
        Object.keys(route.methods).map((method) => `${method} ${route.path}`),
      );
    assert.deepEqual(actual.sort(), expected[index].sort());
  });
});

test("restaurant socket-failure middleware runs before restaurant handlers without affecting orders", async (context) => {
  const checkout = createCheckout(false, { realHttp: true });
  let restaurantReads = 0;
  const app = checkout.createApp({
    ...checkout.dependencies,
    storage: {
      getAll() {
        restaurantReads++;
        return [];
      },
    },
    demoInvestigations: {
      shouldDestroySocket() {
        return true;
      },
    },
  });
  const url = await serveApp(app, context);
  const orders = await fetch(`${url}/api/orders/customer/phone/555-0100`);
  assert.equal(orders.status, 200);
  await assert.rejects(fetch(`${url}/api/restaurant`), TypeError);
  assert.equal(restaurantReads, 0);
});

for (const databaseMode of [false, true]) {
  const mode = databaseMode ? "database" : "memory";
  test(`${mode}: mounted restaurant lookup and order-history URLs retain their responses`, async (context) => {
    const checkout = createCheckout(databaseMode, { realHttp: true });
    const url = await serveApp(checkout.app, context);
    for (const route of [
      "/api/restaurant/restaurant-a",
      "/api/restaurant/by-name/restaurant_a",
    ]) {
      const response = await fetch(url + route);
      assert.equal(response.status, 200);
      assert.equal((await response.json()).id, "restaurant-a");
    }
    const missingMenu = await fetch(`${url}/api/restaurant/by-name/missing`);
    assert.equal(missingMenu.status, 404);
    const history = await fetch(`${url}/api/orders/customer/phone/555-0100`);
    assert.equal(history.status, 200);
    assert.equal((await history.json()).length, databaseMode ? 1 : 0);
    const order = await fetch(`${url}/api/orders/123`);
    assert.equal(order.status, databaseMode ? 200 : 404);
    if (databaseMode) {
      assert.equal((await order.json()).orderId, 123);
      assert.equal(checkout.calls.attributes.orderId, "123");
    }
  });
}

test("mounted demo configuration and dashboard endpoints retain redirects and validation", async (context) => {
  const checkout = createCheckout(false, { realHttp: true });
  const url = await serveApp(checkout.app, context);
  const config = await fetch(`${url}/api/nr-config`);
  assert.equal(config.status, 200);
  const body = await config.json();
  assert.equal(body.armedScenario, null);
  assert.equal(body.armedInvestigation, null);
  const valid = await fetch(`${url}/api/dashboard?demoCode=OU-TEST`, {
    redirect: "manual",
  });
  assert.equal(valid.status, 302);
  assert.equal(valid.headers.get("Cache-Control"), "no-store");
  assert.match(
    valid.headers.get("Location"),
    /^https:\/\/one\.newrelic\.com\/dashboards\/detail\//,
  );
  const invalid = await fetch(`${url}/api/dashboard?demoCode=invalid`, {
    redirect: "manual",
  });
  assert.equal(invalid.status, 400);
});

test("mounted demo controls parse JSON and run side effects only on requested changes", async (context) => {
  const checkout = createCheckout(false, { realHttp: true });
  const url = await serveApp(checkout.app, context);
  const post = (route, body) =>
    fetch(url + route, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  for (const route of ["/api/demo/failures", "/api/demo/investigations"]) {
    const response = await fetch(url + route);
    assert.equal(response.status, 200);
  }
  assert.equal(checkout.calls.sideEffects, 0);
  const invalid = await post("/api/demo/investigations", { slug: "invalid" });
  assert.equal(invalid.status, 400);
  assert.equal(checkout.calls.sideEffects, 0);
  const failure = await post("/api/demo/failures", {
    kind: "order-item",
    target: "Soup",
  });
  assert.equal(failure.status, 200);
  assert.deepEqual(checkout.calls.manualChanges[0], ["order-item", "Soup"]);
  const investigation = await post("/api/demo/investigations", {
    slug: "its-not-checkout",
    seconds: 3,
  });
  assert.equal(investigation.status, 200);
  assert.deepEqual(checkout.calls.manualChanges[1], ["its-not-checkout", 3]);
  assert.equal(checkout.calls.sideEffects, 1);
  const indexFix = await post("/api/demo/investigations", {
    action: "apply-index",
  });
  assert.equal(indexFix.status, 409);
  for (const route of ["/api/demo/failures", "/api/demo/investigations"]) {
    const response = await fetch(url + route, { method: "DELETE" });
    assert.equal(response.status, 200);
  }
  assert.equal(checkout.calls.clearedOverrides, 2);
  assert.equal(checkout.calls.sideEffects, 2);
});

test("mounted simulations retain async errors, timeout responses, and lightweight controls", async (context) => {
  const checkout = createCheckout(false, { realHttp: true });
  const url = await serveApp(checkout.app, context);
  const error = await fetch(`${url}/simulate/error/async-unhandled`);
  assert.equal(error.status, 500);
  assert.equal((await error.json()).errorId, error.headers.get("X-Error-ID"));
  const timeout = await fetch(`${url}/simulate/external-api-timeout`);
  assert.equal(timeout.status, 504);
  assert.match((await timeout.json()).message, /2000ms/);
  const cpu = await fetch(`${url}/simulate/cpu-hog?iterations=10`);
  assert.equal(cpu.status, 200);
  assert.equal((await cpu.json()).performance.iterations, 10);
  const memory = await fetch(`${url}/simulate/memory-leak/clear`);
  assert.equal(memory.status, 200);
  assert.equal(
    await memory.text(),
    "Leaky array cleared. Memory should stabilize.",
  );
  const slow = await fetch(`${url}/simulate/slow-response?delay=1`);
  assert.equal(slow.status, 200);
  assert.equal(await slow.text(), "Response after 1ms delay.");
});

test("dashboard route opens the configured dashboard without exposing credentials", async () => {
  const response = await createCheckout(false).dashboard({
    demoCode: "OU-TEST",
  });
  assert.equal(response.statusCode, 302);
  assert.match(
    response.url,
    /^https:\/\/one\.newrelic\.com\/dashboards\/detail\//,
  );
  assert.equal(response.headers["Cache-Control"], "no-store");
});

test("dashboard route rejects missing or invalid session codes", async () => {
  for (const demoCode of [undefined, "wrong", ["OU-TEST", "OU-AAAA"]]) {
    const response = await createCheckout(false).dashboard({ demoCode });
    assert.equal(response.statusCode, 400);
    assert.equal(response.url, undefined);
  }
});

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
