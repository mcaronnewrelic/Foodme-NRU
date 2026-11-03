const assert = require("node:assert/strict");
const { test } = require("node:test");
const DashboardLinks = require("./dashboard-links");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const guid = "dashboard-guid";

test("stores the playground Hurl state shape with a demoCode selection", async () => {
  let captured;
  const links = new DashboardLinks({
    apiKey: "test-key",
    account: 1352811,
    guid,
    request: async (url, options) => {
      captured = { url, options };
      return new Response(
        `/dashboards/detail/${guid}?account=1352811&state=test-state`,
      );
    },
  });
  const url = await links.getLink("OU-TEST");
  assert.equal(
    url,
    "https://one.newrelic.com/dashboards/detail/dashboard-guid?account=1352811&state=test-state",
  );
  assert.equal(captured.url, "https://hurl.service.newrelic.com/url");
  assert.equal(captured.options.method, "PUT");
  const body = JSON.parse(captured.options.body);
  assert.deepEqual(body.main.urlState, {
    entityGuid: guid,
    selectedVariables: { demoCode: ["OU-TEST"] },
  });
  assert.equal(body.main.id, "dashboards.detail");
  assert.equal(body.platformState.accountId, 1352811);
  assert.equal(body.platformState.timeRange.duration, 604800000);
  assert.ok(!url.includes("test-key"));
});

test("uses the EU service and reuses cached links", async () => {
  let requests = 0;
  const links = new DashboardLinks({
    apiKey: "test-key",
    guid,
    region: "eu",
    request: async (url) => {
      requests++;
      assert.equal(url, "https://hurl.service.eu.newrelic.com/url");
      return new Response(`/dashboards/detail/${guid}?state=test-state`);
    },
  });
  const [first, second] = await Promise.all([
    links.getLink("SIM-TEST"),
    links.getLink("SIM-TEST"),
  ]);
  assert.equal(first, second);
  assert.match(first, /^https:\/\/one\.eu\.newrelic\.com\//);
  assert.equal(requests, 1);
});

test("rejects invalid codes before making requests and bounds the cache", async () => {
  const links = new DashboardLinks({
    apiKey: "test-key",
    guid,
    request: async () =>
      new Response(`/dashboards/detail/${guid}?state=test-state`),
  });
  for (const code of [undefined, ["OU-TEST"], "test", "OU-TEST' OR true"]) {
    await assert.rejects(links.getLink(code), { statusCode: 400 });
  }
  for (let index = 0; index < 105; index++)
    await links.getLink(`OU-${String(index).padStart(4, "0")}`);
  assert.equal(links.cache.size, 100);
});

test("falls back without a key and never redirects to another host or a query", async () => {
  const fallback = new DashboardLinks({ guid });
  assert.equal(
    await fallback.getLink("OU-TEST"),
    "https://one.newrelic.com/dashboards/detail/dashboard-guid?account=1352811",
  );
  for (const path of [
    "//example.com/dashboard?state=test",
    "/launcher/data-exploration.query-builder?state=test",
    `/dashboards/detail/${guid}`,
  ]) {
    const links = new DashboardLinks({
      apiKey: "test-key",
      guid,
      request: async () => new Response(path),
    });
    await assert.rejects(links.getLink("OU-TEST"), /invalid dashboard link/);
    assert.equal(links.cache.size, 0);
  }
});

test("reports Hurl failures without leaking the response body or key", async () => {
  const links = new DashboardLinks({
    apiKey: "test-key",
    guid,
    request: async () => new Response("sensitive response", { status: 403 }),
  });
  await assert.rejects(links.getLink("OU-TEST"), {
    message: "Dashboard state service returned HTTP 403",
  });
  assert.equal(links.cache.size, 0);
});

test("each personal dashboard widget uses the demoCode template variable", () => {
  const dashboard = JSON.parse(
    readFileSync(
      path.join(__dirname, "../newrelic/dashboards/orderup-overview.json"),
      "utf8",
    ),
  );
  const page = dashboard.pages.find((page) => page.name === "Knowledge checks");
  for (const title of [
    "Your answers",
    "Your first-try score",
    "Your orders",
    "Your answer history",
  ]) {
    const widget = page.widgets.find((widget) => widget.title === title);
    assert.ok(widget, `Missing widget: ${title}`);
    for (const query of widget.rawConfiguration.nrqlQueries)
      assert.match(query.query, /demoCode = \{\{demoCode\}\}/);
  }
  const variable = dashboard.variables.find(
    (variable) => variable.name === "demoCode",
  );
  assert.equal(variable.replacementStrategy, "STRING");
  assert.match(variable.nrqlQuery.query, /ItemsOrdered/);
  assert.match(variable.nrqlQuery.query, /PageView/);
});
