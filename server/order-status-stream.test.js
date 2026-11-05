const assert = require("node:assert/strict");
const { test } = require("node:test");
const http = require("node:http");
const { WebSocket } = require("ws");
const OrderStatusStream = require("./order-status-stream");

function nextMessage(socket) {
  return new Promise((resolve, reject) => {
    socket.once("message", (data) => {
      try {
        resolve(JSON.parse(String(data)));
      } catch (err) {
        reject(err);
      }
    });
    socket.once("error", reject);
  });
}

test("subscribe answers with a snapshot, publish pushes advances to subscribers only", async (t) => {
  const statuses = new Map([["42", "preparing"]]);
  const stream = new OrderStatusStream(null, async (id) => statuses.get(id) ?? null);
  const server = http.createServer();
  stream.attach(server);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => {
    stream.close();
    server.close();
  });
  const port = server.address().port;

  const socket = new WebSocket(`ws://127.0.0.1:${port}/api/orders/stream`);
  await new Promise((resolve, reject) => {
    socket.once("open", resolve);
    socket.once("error", reject);
  });
  t.after(() => socket.terminate());

  socket.send(JSON.stringify({ type: "subscribe", orderId: "42" }));
  const snapshot = await nextMessage(socket);
  assert.deepEqual(snapshot, { type: "status", orderId: "42", status: "preparing" });

  // An advance for a different order must not reach this subscriber.
  stream.publish("99", "delivered");
  const advanced = nextMessage(socket);
  stream.publish("42", "out_for_delivery");
  assert.deepEqual(await advanced, {
    type: "status",
    orderId: "42",
    status: "out_for_delivery",
  });

  // Unknown orders snapshot as pending (the tracker's initial stage).
  const other = new WebSocket(`ws://127.0.0.1:${port}/api/orders/stream`);
  await new Promise((resolve, reject) => {
    other.once("open", resolve);
    other.once("error", reject);
  });
  t.after(() => other.terminate());
  other.send(JSON.stringify({ type: "subscribe", orderId: "7" }));
  assert.deepEqual(await nextMessage(other), {
    type: "status",
    orderId: "7",
    status: "pending",
  });
});

test("a connection is one background transaction plus one OrderStreamSample at close", async (t) => {
  const calls = { transactions: [], events: [] };
  const fakeNewrelic = {
    startBackgroundTransaction(name, callback) {
      const record = { name, ended: false, attributes: null };
      calls.transactions.push(record);
      void (async () => {
        await callback();
      })();
      return undefined;
    },
    getTransaction() {
      const record = calls.transactions[calls.transactions.length - 1];
      return { end() { record.ended = true; } };
    },
    addCustomAttributes(attributes) {
      calls.transactions[calls.transactions.length - 1].attributes = attributes;
    },
    recordCustomEvent(type, attributes) {
      calls.events.push({ type, attributes });
    },
  };
  // The fake's transaction callback completes only when the stream
  // releases it at close; capture completion via the record itself.
  const stream = new OrderStatusStream(null, async () => "preparing", fakeNewrelic);
  const server = http.createServer();
  stream.attach(server);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => {
    stream.close();
    server.close();
  });
  const port = server.address().port;

  const socket = new WebSocket(`ws://127.0.0.1:${port}/api/orders/stream`);
  await new Promise((resolve, reject) => {
    socket.once("open", resolve);
    socket.once("error", reject);
  });
  socket.send(JSON.stringify({ type: "subscribe", orderId: "42" }));
  await nextMessage(socket); // snapshot
  const advanced = nextMessage(socket);
  stream.publish("42", "delivered");
  await advanced;

  socket.close(1000);
  await new Promise((resolve) => socket.once("close", resolve));
  // Let the released transaction callback settle.
  await new Promise((resolve) => setImmediate(resolve));
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(calls.transactions.length, 1);
  assert.equal(calls.transactions[0].name, "OrderStatusStream/connection");
  assert.equal(calls.transactions[0].ended, true);
  assert.deepEqual(calls.transactions[0].attributes, {
    messagesReceived: 1,
    messagesSent: 2,
    pushesSent: 1,
    orderId: "42",
  });
  assert.equal(calls.events.length, 1);
  assert.equal(calls.events[0].type, "OrderStreamSample");
  assert.equal(calls.events[0].attributes.orderId, "42");
  assert.equal(calls.events[0].attributes.messagesReceived, 1);
  assert.equal(calls.events[0].attributes.messagesSent, 2);
  assert.equal(calls.events[0].attributes.pushesSent, 1);
  assert.equal(calls.events[0].attributes.closeCode, 1000);
  assert.equal(typeof calls.events[0].attributes.connectedDurationMs, "number");
});

test("upgrades to other paths are refused", async (t) => {
  const stream = new OrderStatusStream(null, async () => null);
  const server = http.createServer();
  stream.attach(server);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => {
    stream.close();
    server.close();
  });
  const port = server.address().port;

  const socket = new WebSocket(`ws://127.0.0.1:${port}/api/orders`);
  await assert.rejects(
    new Promise((resolve, reject) => {
      socket.once("open", resolve);
      socket.once("error", reject);
    }),
  );
  socket.terminate();
});
