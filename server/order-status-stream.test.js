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
