const { Router } = require("express");
const bodyParser = require("body-parser");

module.exports = function createDemoRouter({
  logger,
  environment,
  demoFailures,
  demoInvestigations,
  dashboardLinks,
}) {
  const router = Router();
  const jsonParser = bodyParser.json();

  // Lets the Angular "Behind the scenes" callouts build New Relic links for the current account
  router.get("/nr-config", (req, res) => {
    const scenario = demoFailures.getState();
    const investigation = demoInvestigations.getState();
    res.json({
      accountId: environment.NEW_RELIC_ACCOUNT_ID || null,
      browserEntityGuid: environment.NEW_RELIC_BROWSER_ENTITY_GUID || null,
      // Shown in the site's behind-the-scenes content so learners are not
      // guessing which target fails; the checks still have to find the
      // failure in the data. Null when nothing is armed.
      armedScenario: scenario.armed
        ? { ...scenario.armed, source: scenario.source }
        : null,
      // Which investigation (spec section 11) is armed, if any: the banner
      // names it and its page opens. Null when none is live.
      armedInvestigation: investigation.armed
        ? { ...investigation.armed, source: investigation.source }
        : null,
    });
  });

  router.get("/dashboard", async (req, res) => {
    res.setHeader("Cache-Control", "no-store");
    try {
      res.redirect(await dashboardLinks.getLink(req.query.demoCode));
    } catch (error) {
      if (error.statusCode === 400)
        return res.status(400).json({ error: error.message });
      logger.warn(
        { err: error },
        "Dashboard deep link unavailable; opening dashboard without a preset code",
      );
      res.redirect(dashboardLinks.fallbackUrl);
    }
  });

  // Demo failure scenarios: read the current state, arm one manually, or
  // clear the manual override (back to env / weekly rotation). Deliberately
  // unauthenticated — a teaching demo; changes are logged. See
  // demo-failures.js for the priority rules.
  router.get("/demo/failures", (req, res) => {
    res.json(demoFailures.getState());
  });

  router.post("/demo/failures", jsonParser, (req, res) => {
    const { kind, target } = req.body || {};
    if (kind === "off") {
      const state = demoFailures.setManual("off");
      logger.info(
        { ip: req.ip },
        "Demo failure scenario disarmed by manual override",
      );
      return res.json(state);
    }
    if (
      !["restaurant", "order-restaurant", "order-item"].includes(kind) ||
      !target
    ) {
      return res.status(400).json({
        error:
          'Body must be {kind: "restaurant" | "order-restaurant" | "order-item", target: "<name or slug>"}, or {kind: "off"}',
      });
    }
    const state = demoFailures.setManual(kind, String(target));
    logger.info(
      { kind, target: state.armed?.target, ip: req.ip },
      "Demo failure scenario armed by manual override",
    );
    return res.json(state);
  });

  router.delete("/demo/failures", (req, res) => {
    const state = demoFailures.clearManual();
    logger.info({ ip: req.ip }, "Demo failure manual override cleared");
    res.json(state);
  });

  // Demo investigations: read the armed state, arm one manually, clear
  // the override, or disarm until cleared. Same deliberately
  // unauthenticated teaching-demo pattern as /api/demo/failures.
  router.get("/demo/investigations", (req, res) => {
    res.json(demoInvestigations.getState());
  });

  router.post("/demo/investigations", jsonParser, async (req, res) => {
    const { slug, seconds, action } = req.body || {};
    if (action === "apply-index") {
      // I8's fix, applied by the instructor mid-investigation.
      const result = await demoInvestigations.applyIndexFix();
      if (!result.ok) return res.status(409).json(result);
      logger.info(
        { ip: req.ip },
        "Demo investigation fix applied: index on customers(phone)",
      );
      return res.json(result.state);
    }
    if (slug === "off") {
      const state = demoInvestigations.setManual("off");
      logger.info(
        { ip: req.ip },
        "Demo investigation disarmed by manual override",
      );
      void demoInvestigations.syncSideEffects();
      return res.json(state);
    }
    if (
      slug !== "its-not-checkout" &&
      slug !== "the-502-didnt-come-from-the-app" &&
      slug !== "one-connection-for-the-whole-restaurant" &&
      slug !== "the-table-is-locked" &&
      slug !== "the-slow-lookup" &&
      slug !== "the-kitchen-never-got-the-ticket"
    ) {
      return res.status(400).json({
        error:
          'Body must be {slug: "its-not-checkout", seconds?: 1-10}, {slug: "the-502-didnt-come-from-the-app"}, {slug: "one-connection-for-the-whole-restaurant"} (armed by scripts/burst-orders.js), {slug: "the-table-is-locked"}, {slug: "the-slow-lookup"}, {slug: "the-kitchen-never-got-the-ticket"}, {action: "apply-index"} (I8 fix, while I8 is armed), or {slug: "off"}',
      });
    }
    const state = demoInvestigations.setManual(slug, seconds);
    logger.info(
      { slug, seconds: state.armed?.seconds, ip: req.ip },
      "Demo investigation armed by manual override",
    );
    void demoInvestigations.syncSideEffects();
    res.json(state);
  });

  router.delete("/demo/investigations", (req, res) => {
    const state = demoInvestigations.clearManual();
    logger.info({ ip: req.ip }, "Demo investigation manual override cleared");
    void demoInvestigations.syncSideEffects();
    res.json(state);
  });

  return router;
};
