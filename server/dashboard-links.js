const ENVIRONMENTS = {
  us: {
    base: "https://one.newrelic.com",
    hurl: "https://hurl.service.newrelic.com/url",
  },
  eu: {
    base: "https://one.eu.newrelic.com",
    hurl: "https://hurl.service.eu.newrelic.com/url",
  },
};
const DEFAULT_GUID = "MTM1MjgxMXxWSVp8REFTSEJPQVJEfGRhOjEzNDMxMzI3";

class DashboardLinks {
  constructor({
    apiKey,
    account = 1352811,
    guid = DEFAULT_GUID,
    region = "us",
    request = fetch,
  } = {}) {
    if (!ENVIRONMENTS[region])
      throw new Error("Dashboard region must be us or eu");
    if (!Number.isSafeInteger(Number(account)) || Number(account) <= 0) {
      throw new Error("Dashboard account must be a positive integer");
    }
    this.apiKey = apiKey;
    this.account = Number(account);
    this.guid = guid;
    this.environment = ENVIRONMENTS[region];
    this.request = request;
    this.cache = new Map();
    this.fallbackUrl = `${this.environment.base}/dashboards/detail/${encodeURIComponent(guid)}?account=${this.account}`;
  }

  async getLink(demoCode) {
    if (
      typeof demoCode !== "string" ||
      !/^(OU|SIM)-[A-Z0-9]{4}$/.test(demoCode)
    ) {
      const error = new Error("A valid demoCode is required");
      error.statusCode = 400;
      throw error;
    }
    if (!this.apiKey) return this.fallbackUrl;
    const cached = this.cache.get(demoCode);
    if (cached && cached.expiresAt > Date.now()) return cached.promise;
    this.cache.delete(demoCode);
    if (this.cache.size >= 100)
      this.cache.delete(this.cache.keys().next().value);
    const promise = this.generateLink(demoCode);
    this.cache.set(demoCode, {
      promise,
      expiresAt: Date.now() + 10 * 60 * 1000,
    });
    try {
      return await promise;
    } catch (error) {
      if (this.cache.get(demoCode)?.promise === promise)
        this.cache.delete(demoCode);
      throw error;
    }
  }

  async generateLink(demoCode) {
    const response = await this.request(this.environment.hurl, {
      method: "PUT",
      headers: { "API-Key": this.apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({
        launcher: { id: "dashboards.launcher", urlState: {} },
        main: {
          id: "dashboards.detail",
          urlState: {
            entityGuid: this.guid,
            selectedVariables: { demoCode: [demoCode] },
          },
        },
        platformState: {
          accountId: this.account,
          timeRange: { duration: 604800000 },
        },
      }),
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok)
      throw new Error(
        `Dashboard state service returned HTTP ${response.status}`,
      );
    const path = (await response.text()).trim();
    const url = new URL(path, this.environment.base);
    const expectedPath = `/dashboards/detail/${encodeURIComponent(this.guid)}`;
    if (
      !path.startsWith("/") ||
      url.origin !== this.environment.base ||
      url.pathname !== expectedPath ||
      !url.searchParams.get("state")
    ) {
      throw new Error(
        "Dashboard state service returned an invalid dashboard link",
      );
    }
    return url.href;
  }
}

module.exports = DashboardLinks;
