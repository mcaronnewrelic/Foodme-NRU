# Try / Learn / Find / Check Spec — Foodme

**Version:** 0.2 · 2026-10-31 (v0.2: new §11 — Investigations for Foodme: the
four browser.nru.to investigations ported, plus five infrastructure-native
ones built on nginx and Postgres. v0.1: the Try/Learn/Find/Check loop.)

**Update (2026-11-01 — the OrderUp rename, PR #22 + Michael's decisions):**
the app is renamed **OrderUp**: the New Relic app name, the site brand, and
the demoCode prefix (**OU-XXXX**, storage keys `orderup-*`, progress key
`orderup-missions` in §2). The check event in §3 is named
**`OrderupQuizAnswer`** (Michael's call — renamed before it ever fired, so
no data split; read every `FoodmeQuizAnswer` below as `OrderupQuizAnswer`,
including the §8 dashboard queries). Callout NRQL filters now use
`appName = 'OrderUp'`.
**Goal:** Foodme's “Behind the scenes” callouts currently *annotate* the app —
they show the NRQL a page produces, but ask nothing of the visitor. This spec
turns them into the loop that browser.nru.to runs on every page:

- **Try it** — one concrete action in the app, with a visible result.
- **Learn it** — the callout explains what data that action just created, and why.
- **Find it** — one click opens that exact data in New Relic, scoped to *this*
  visitor wherever the data allows it.
- **Check yourself** — one question per stop. At least half the checks are
  **evidence checks**: the answer is a value only the data has (a requestId, an
  error message, a count), so the check can't be passed by guessing without
  opening New Relic. Every answer is recorded as an event, so a knowledge-checks
  dashboard can be built on it later exactly as on browser.nru.to.

**Non-goals:** no change to the customer-mode experience (callouts and missions
exist only in Behind-the-scenes mode); no new pages in the ordering flow; no
live dashboard changes in this spec (§8 specifies one, building it is separate).

**Reference implementation:** browser.nru.to — per-page loop, `demoCode`
identity, `DemoQuizAnswer` events, the deep-link spec at
`~/workspace/browser-nru-to/deep-link-spec.md`. Where this spec says “as on
browser.nru.to”, copy that pattern, not its code.

---

## 0. Prerequisites (do these first)

- **P1 — Fix the query-link pattern.** `NrConfigService.nrqlUrl()` builds the
  NR1 `pane=` launcher URL. That format was tested live on 2026-10-28 and
  **failed**: the URL is rewritten to an opaque `state=` form, the query does
  not pre-fill, and the UI can land in the wrong account. Replace the body with
  the pattern verified working the same day:
  `https://insights.newrelic.com/accounts/{accountId}/query?query={encodeURIComponent(nrql)}`.
  Keep all URL building inside `nrqlUrl()` so a future pattern change is again
  a one-function change. (The legacy surface could be retired one day; the
  printed NRQL + the new Copy button in §5 are the permanent fallback.)
  **Update (2026-11-01):** P1 is implemented in PR #6 but Michael is holding
  the merge while testing. His reason: the `pane=` console, when it works,
  opens results in **table mode**, which he prefers for teaching; the Insights
  pattern reliably pre-fills but lands in **JSON output mode**. Open question
  he is testing: whether `pane=` behaves differently (works) in the Foodme
  account (1352811) than it did in Enablement (6932347), or whether either
  pattern has a variant that lands in table view. PR #6 stays open as the
  known-working fallback; P2 is done (nr-config returns real values).
- **P2 — Env populated.** `NEW_RELIC_ACCOUNT_ID` and
  `NEW_RELIC_BROWSER_ENTITY_GUID` set in the deployment's `.env`, confirmed by
  `GET /api/nr-config` returning non-null values. Without P2 every button in
  this spec silently disappears.

## 1. Identity: give every visitor a code

**Update (2026-10-31, Michael's decisions, built in PR #10, stacked on the §1 PR #9):** the customer's *name is the demoCode* — there is no personal name anywhere. Email is **removed from the product entirely** (form, model, order payload, NR attributes, the by-email lookup endpoint, the customers table on fresh installs): in a shared demo it was a PII trap. Instead, the Customer page pre-fills a generated sample customer — name = demoCode, phone in the reserved (503) 555-01xx fictional range, generated Portland address — with copy asking visitors not to substitute real details. Order lookup is by sample phone only; server user IDs derive from the name (the code). Missions below should treat `demoCode`/`enduser.id` as the only identity; nothing in §2 may ask for or key on a name or email.

**Update (2026-11-01, SIM- codes):** the browser.nru.to exclusion
convention is adopted: simulated visitors may carry SIM-XXXX codes
(the identity service and the server's order-payload validation both
accept the prefix; a code can be pinned with ?demoCode= or a
pre-seeded localStorage entry), and the scripted dashboards exclude
them with demoCode NOT LIKE 'SIM-%'. No simulated traffic exists yet;
this is the future-proofing, documented in docs/MISSIONS.md.


browser.nru.to's loop works because `demoCode` ties a visitor to their data.
Foodme has a name → `setUserId()` → `enduser.id`, which is real but not enough:
names collide in a workshop, and several data types are easier to filter by a
short code.

- On first visit, generate a session code `FM-XXXX` (4 chars, unambiguous
  alphabet as on browser.nru.to), persist in `localStorage` key
  `foodme-demo-code`, show it in the header next to the Behind-the-scenes
  toggle **when callouts are on**: “Your code: FM-XXXX — your data carries it.”
- Stamp it everywhere via the browser agent: `setCustomAttribute('demoCode', code)`
  on load and on every route change (the app already sets a `page` attribute
  per page — same hook), so PageView, AjaxRequest, PageAction, JavaScriptError
  and BrowserInteraction all carry it.
- Server side: the API already propagates `requestId`; also accept the code from
  the client (header or order payload) and stamp it as a custom attribute on
  the `POST /api/order` transaction and the `Order` custom event, so the
  Thank You queries can filter by code as well as requestId.
- The Customer page's existing callout stays the “who you are” explainer; add
  the code to its copy: name → `enduser.id`, code → `demoCode`, both attached
  to everything after.

## 2. The mission path

Five missions follow the ordering journey — the path *is* the app's own flow,
so no new navigation is invented. A slim progress strip appears at the top of
each page **in callout mode only**: “Mission 2 of 5 · Find a menu in the data”
with the five stops as ticks. State persists in `localStorage`
(`foodme-missions`): per mission, `tried` (the Try action was observed),
`found` (the Find link was clicked), `checked` (the Check was answered
correctly, plus attempts). A “Your journey” summary lives on How It Works (§6).

Each mission block is the existing callout, extended (§5): Try line first
(with the control it names highlighted by a pulsing outline while the mission
is active — optional, cut if it fights the CSS), then Learn copy, the NRQL,
the Find button, then the Check.

### Mission 1 — Say who you are (Customer page)

- **Try:** enter your name and continue.
- **Learn:** the existing callout copy — `setUserId()` makes your name the
  `enduser.id`; every page view, AJAX call, action and error after that
  carries it, plus your `demoCode` (§1).
- **Find:** existing `userNrql`, with the code added:
  `SELECT count(*) FROM PageView, AjaxRequest, PageAction, JavaScriptError WHERE demoCode = '<code>' FACET enduser.id, eventType() SINCE 1 day ago`
- **Check (evidence):** “Open Find it. How many event types carry your code so
  far?” — numeric entry; correct = the live facet count at answer time
  (accept the value the query returns when they clicked Find; store it with
  the answer event). Fallback if that proves fragile: multiple choice
  (1 / 2 / 3 or more) judged against the same count.

### Mission 2 — Every menu is a transaction (Restaurants → Menu)

- **Try:** open any restaurant's menu; then use search/filter once.
- **Learn:** each menu load is `GET /api/restaurant/…`, an APM transaction;
  filtering is client-side and creates *no* new request — the absence is the
  lesson.
- **Find:** the Menu page's two existing callouts (requests, and requests by
  status code), scoped: append `WHERE demoCode = '<code>'` is not possible on
  APM Transaction — instead facet/filter by the page's own attributes as the
  callouts already do; keep cohort view but say so in the copy (“this one
  shows everyone's menus — transactions don't carry your browser code”).
  Honesty about which queries are personal and which are cohort is part of
  the teaching.
- **Check (reasoning):** “You filtered the list and no new request appeared in
  the data. Why?” — options: the filter runs in your browser / the server hid
  it / New Relic dropped it. Correct: in the browser.

### Mission 3 — Place the order, keep the receipt (Checkout → Thank You)

- **Try:** check out with any cart and reach Thank You.
- **Learn:** the order is three records of one act: an `Order` custom event, a
  `POST /api/order` transaction, and `Custom/Orders/*` metrics — all sharing
  the `requestId` printed on this page. That shared key is how you stitch a
  user action to backend truth.
- **Find:** the Thank You page's three existing callouts, unchanged — they are
  already requestId-scoped, the best Find on the site.
- **Check (evidence):** “Paste the last 4 characters of this order's
  requestId.” Text entry, exact match against the page's own value. (Trivial
  for the visitor, impossible to fake having reached this page with an order —
  it proves the Try happened. The harder variant: ask for the order's
  `duration` from the transaction query, rounded to the nearest 10 ms,
  tolerance ±20 ms.)

### Mission 4 — Find it again later (Orders page)

- **Try:** look up the order you just placed from the Orders page.
- **Learn:** the lookup finds the order *without* an email address — the
  existing callout's point; connect it back to Mission 3: requestId and code
  are the join keys, not personal data.
- **Find:** existing `ordersNrql` plus the code filter where the event type
  supports it.
- **Check (reasoning):** “The Orders lookup works without your email. Which
  two values actually identify your order in the data?” — multi-select:
  requestId + demoCode (distractors: email, IP address, browser type).

### Mission 5 — Break it on purpose (How It Works + armed failures)

Two halves; the second activates only when a failure is armed (§7).

- **Try (always available):** trigger the simulated error on How It Works.
- **Learn:** one click, three traces: a JavaScriptError, a PageAction
  (`error_simulation_triggered`), and the round-trip time — the existing three
  callouts, reordered into that story.
- **Find:** the existing three queries.
- **Check (evidence):** “In the PageAction data, what `errorType` did your
  simulated error record?” — text entry matched against the value the
  simulation writes.
- **Try (armed only):** if a `DEMO_FAILING_*` switch is on, the mission
  becomes “Hunt the planted failure”: the scenario banner (§7) names the
  symptom only (“Some orders are failing”). The student reproduces it, then
  uses the Menu status-code callout → `FROM TransactionError WHERE
  restaurantSlug IS NOT NULL` → the trace → Errors Inbox — the path already
  sketched in `docs/NEW_RELIC_DEMO.md`, promoted into the app.
- **Check (evidence):** “What is the exact error message on the failing
  transaction?” — text entry, normalised (trim, case-insensitive) match
  against the armed failure's message (`Menu data … is corrupted`,
  `Kitchen at "…" is not accepting orders`, `Inventory check failed for "…"`).
- **Case closed:** completing Mission 5 (either half, plus 1–4) completes the
  path: progress strip shows 5/5 and How It Works shows the completion block
  with the §8 dashboard link.

**Update (2026-11-01, PR #24 — Missions 1–2 built):** the progress strip
exists (an `app-mission-strip` in the app shell — one mount point rather
than per page — callout mode only, ticks link to each mission's start
page), and MissionProgressService carries per-mission `tried`/`found`
alongside the per-question state. Mission 1 is built as written, with
the check in the spec's fallback form (choice: 1 / 2 / 3 or more): the
answer key is an EventTypesService that tracks the four faceted types
from the app's own actions (HTTP interceptor → AjaxRequest, route
changes → PageView, addPageAction → PageAction, noticeError →
JavaScriptError), persisted in localStorage — the same count the Find
query returns, without needing to read the query result back. Mission
2's tried hook lives on the Restaurants page: using any filter marks
it (the filter is there, not on the Menu page). Missions 3–5 are
declared in the mission registry (services/missions.ts) so the strip
is complete; their checks and framing are the follow-on PRs, and §6's
hub + completion block come with Mission 5's.

**Update (2026-11-01, PR #25 — Missions 3–4 built):** Mission 3 as
written (tried = arriving on Thank You with an order; the metrics
callout also gained the cohort chip). Mission 4's "code filter where
the event type supports it" turned out to be possible after all, in
disguise: lookup transactions carry no demoCode, but they are stamped
`userID`, which the server derives from the customer's name — and the
name is the demoCode — so the Find query filters
`userID = '<userId>'` via the §5.2 token system, the token computed
client-side exactly as the server derives it (`user_` + code,
lowercased, non-alphanumerics as `_`). The callout copy explains the
disguise; it teaches the join-key point better than the raw code
would. Remaining: §6 hub + Mission 5 (PR D).

**Update (2026-11-01, PR #26 — Mission 5 + hub built; missions complete):**
Mission 5's first half rides the existing three callouts unchanged in
order (they already matched the spec's story); the check's answer is
`sync`, the errorType the simulation writes. The armed half builds its
answer key client-side from the armed scenario using the server's own
message templates, verified against server/index.js — with one
asymmetry worth remembering: the menu failure's message embeds the
route **slug** (`target`), the order failures embed **display names**
(`targetName`), and all three carry suffixes (": stock count is -2",
": ticket printer offline", ": menu_items.category is null for 3
rows"). The registry's `altQuestionId` makes Mission 5 checked when
either half is solved. The §6 hub ("Your journey": mission states,
checked count, first-try score, case-closed block) links the OrderUp
Overview dashboard for now; §8's knowledge-checks page retargets that
link when built. All five missions are now built; §8 and §11 remain.

## 3. Check-yourself mechanics

- One reusable component, `<app-nr-check>`, rendered inside the callout after
  the Find button. Inputs: `missionId`, `questionId`, `kind`
  (`choice` | `multi` | `number` | `text`), options/answer config, tolerance
  for numbers.
- Wrong answer: inline “Not what the data says — check the Find it result and
  try again”, attempts counted, no lockout. Correct: the mission tick fills,
  one line on what the answer proves (“That's the join key for this order.”).
- Every answer (right or wrong) fires a browser-agent custom event
  **`FoodmeQuizAnswer`** via `addPageAction` or `recordCustomEvent`, with
  attributes mirroring `DemoQuizAnswer` on browser.nru.to so the dashboard
  queries port directly:
  `missionId`, `questionId`, `question`, `answer`, `outcome`
  (`correct`/`incorrect`), `attempt` (1-based per question per visitor),
  `demoPage` (route), `demoCode`, `enduser.id` (from the agent context).
- Checks are hidden in customer mode with the rest of the callout.

## 4. (Reserved — merged into §2/§3.)

## 5. Callout component upgrades

Small, shared, do once:

1. **Copy NRQL button** next to the `<pre>` — the permanent fallback if the
   link pattern ever breaks (see P1).
2. **Placeholder resolution in NRQL strings:** support `<code>` (the visitor's
   demoCode) and `<requestId>` tokens in a callout's NRQL, replaced at render
   time. Today's callouts hand-interpolate in TypeScript; the token keeps new
   callouts declarative. The *printed* NRQL shows the resolved values, so what
   you read is exactly what opens.
3. **Cohort honesty label:** optional `scope="personal|cohort"` input; cohort
   callouts render a small “Shows everyone's data” chip — see Mission 2.
4. **One-time account note** under the first Find button on each page (as on
   browser.nru.to): “Opens in the shared demo account — sign in there first.
   In your own account the query runs but finds no Foodme data.”
5. **Errors Inbox button** stays as is (`showBrowserErrors`), GUID-driven.

## 6. How It Works becomes the hub

- Mission map: the five missions with state (done / current / locked-by-mode),
  the “Your journey” summary (missions complete, first-try score), and the
  completion block from Mission 5.
- The simulated-error section stays, now framed as Mission 5's first half.
- A link to the §8 dashboard (“See the whole class's answers” for instructors;
  “See your journey” for students once the variable is picked).

## 7. Instructor mode: surface the armed failure

**Update (2026-11-01, Michael's direction, built in PR #13):** the design below was superseded in two ways. (1) Arming is no longer env-only: `server/demo-failures.js` resolves one scenario by priority — env `DEMO_FAILING_*` > manual override (unauthenticated `GET/POST/DELETE /api/demo/failures`, persisted to `server/data/demo-failures.json`, controlled from a How It Works instructor panel) > a **deterministic weekly rotation** over the seed restaurants/items (ISO-week hash), so the failing target changes weekly with no human action. (2) The armed target **is** exposed (kind + display name + source) in `armedScenario` and in a behind-the-scenes banner — Michael judged blind guessing a burden, not the exercise; the investigation missions in §11 that need a hidden culprit should rely on the infra faults (also instructor-armed) rather than these three switches. Mission 5's "armed half" should read `armedScenario` as built: `{kind: 'restaurant' | 'order-restaurant' | 'order-item', target, targetName, source}`.

- Extend `GET /api/nr-config` with `armedScenario`: `null`, or
  `{ kind: 'menu' | 'order-restaurant' | 'order-item' }` derived server-side
  from which `DEMO_FAILING_*` variables are set. **Never** expose the slug
  itself — the banner gives the symptom, finding the culprit is the mission.
- When non-null and callouts are on, a banner under the header reads:
  “Today's scenario: something in the app is failing on purpose. Mission 5
  will help you hunt it.” Mission 5's armed half (§2) unlocks.
- `?callouts=1` URL parameter forces callouts on for that visit (instructor
  handout links, QR codes), without changing the stored preference.

## 8. Dashboard follow-on (spec only — do not build with this spec)

- Add a `demoCode` variable to the scripted **FoodMe Overview** dashboard
  (Query type, `SELECT uniques(demoCode) FROM FoodmeQuizAnswer SINCE 1 week
  ago` — noting the browser.nru.to lesson: a brand-new code appears only
  after its first answer lands).
- New page “Knowledge checks”: cohort widgets ported from browser.nru.to's
  dashboard of the same name (answers count, first-try %, hardest questions,
  most-picked wrong answers, tries needed) over `FoodmeQuizAnswer`, plus a
  “Your journey” section filtered by the variable.
- New page “Missions”: completion funnel over `FoodmeQuizAnswer` +
  `Order` events (started → ordered → checked → case closed).
- Site link (L3): the How It Works completion block and mission map link here
  with the plain dashboard URL — dashboard variables cannot be set from a
  readable URL parameter (verified 2026-10-28); the page copy says “pick your
  code at the top”.

## 9. Build order

1. P1 link-pattern fix + P2 env (unblocks every Find button).
2. §5 callout upgrades (copy button, tokens, scope chip, account note).
3. §1 identity code (needed by Find scoping, checks, and §8).
4. §3 check component + `FoodmeQuizAnswer` event.
5. §2 missions 1–4 (content + progress strip + persistence).
6. §6 hub + Mission 5 first half.
7. §7 instructor mode + Mission 5 armed half.
8. §8 dashboards (separate go-ahead).

## 10. Acceptance tests

- **A1** With env set, every Find button opens New Relic with the query
  pre-filled, in the Enablement account, showing the visitor's own data where
  the mission claims personal scope.
- **A2** With env *unset*, callouts still render, NRQL still prints, Copy
  works, buttons hide, nothing errors in the console.
- **A3** A fresh browser gets a code; the code survives reload, appears in the
  header in callout mode, and is present on PageView/PageAction events in NR.
- **A4** Each Check records a `FoodmeQuizAnswer` with all §3 attributes;
  wrong answers increment `attempt`; a correct answer fills the mission tick
  and survives reload.
- **A5** Evidence checks reject wrong values (Mission 3 with another order's
  requestId suffix; Mission 5 with a paraphrased error message).
- **A6** With `DEMO_FAILING_ORDER_ITEM` set, `/api/nr-config` reports
  `armedScenario.kind = 'order-item'` and **not** the item slug; the banner
  shows; Mission 5's armed half is completable end-to-end.
- **A7** Customer mode (callouts off) is byte-for-byte the app as it is today:
  no strip, no banner, no checks, no code in the header.
- **A8** Progress strip and mission state are correct after completing
  missions out of order and after clearing only the customer (not the code).

---

## 11. Investigations

The four question-gated Investigations from browser.nru.to, ported — plus five
that only Foodme can run, because browser.nru.to has no proxy and no real
database. Same format contract as the originals: **6 checkpoints**, one
question each; a correct answer reveals the next step and how to see it in New
Relic; wrong answers are retryable; answers are recorded (here, as
`FoodmeQuizAnswer` with `missionId = 'inv-<slug>'`); each ends with “Case
closed” and real-world next steps. Per the lesson from the originals'
review, **at least two checkpoints per investigation are evidence checks**
(a value only the data has), not reasoning questions.

**Fault model differs on purpose.** The originals fault on a clock (no
instructor present). Foodme investigations are **armed** by the instructor
through env switches, matching the existing `DEMO_FAILING_*` pattern, and are
surfaced through the §7 scenario banner — the banner names which investigation
is live, never the culprit. One investigation armed at a time. Each also gets
a page on a Foodme **Evidence Board** (extension of §8: one page per
investigation, widgets `SINCE 3 hours ago`, same as the browser.nru.to board).
NRQL below is indicative — confirm event/attribute names against live data
while building (nri-nginx → `NginxSample` + parsed access logs; nri-postgresql
→ `Postgresql*Sample` and the config's custom-query metrics).

Placement: linked from How It Works under “Investigations”, shown only in
callout mode; the customer experience is untouched.

### 11.1 The four ports

**I1 · Who's stealing the CPU?** — identical chain, real cast: symptom
(slow pages) → APM service → the slow transaction → container facet
(`foodme-app` / `foodme-db` / `foodme-nginx`) → host → `ProcessSample` hog.
Arm: a CPU-burning sidecar or a `stress` thread in one container
(`DEMO_INFRA_CPU_CONTAINER`). Evidence check: the hog process's peak
`cpuPercent` bucket (±10%).

**I2 · It's not checkout** — `POST /api/order` is slow and the guilty span is
the **datastore span into Postgres**, not app code. Chain: checkout symptom →
trace → database span carries the time → the query text → the table →
why *that* query is slow right now (bridge to I7/I8 if either is also armed;
standalone, arm with `DEMO_DB_SLOW_ORDER_QUERY` adding an artificial delay
or an unindexed sort). Evidence check: the database span's share of total
trace duration (nearest 10%).

**I3 · One page, a dozen calls — twice** — the fan-out exists at two layers:
HTTP (page → API) and SQL (request → one query per menu item / order line
against `menu_items` / `order_items`). Chain alternates layers and the
mid-investigation twist is checkpoint 4: “You've counted the calls. Now count
the queries — which layer is the N+1 in?” Evidence checks: product calls per
catalog request (as the original) *and* queries per order (from datastore
span counts).

**I4 · A deploy broke it** — as the original (deployment marker, error burst,
Errors Inbox group), plus Foodme's own variant noted in copy: a “deploy” here
can also be nginx serving a **stale hashed Angular bundle** against a changed
API — the checkpoint-6 question asks which of the two this incident was,
judged from whether the errors are JS errors (bundle) or transaction errors
(API).

### 11.2 New: the infrastructure set

**I5 · The 502 didn't come from the app** (nginx)
- *Symptom:* intermittent 502s; the app logs nothing; APM shows no matching errors.
- *Arm:* `DEMO_NGINX_UPSTREAM_TIMEOUT` — a per-route override dropping
  `proxy_read_timeout` for `/api/` to ~2s while one endpoint is slow (or an
  upstream that restarts on a cycle). Note for the Learn copy: production
  config sets `proxy_read_timeout 86400s` on `/api/` — a sick upstream hangs
  instead of failing; the investigation's timeout is the fix shown early.
- *Chain:* (1) status-code split by source — nginx access-log metrics vs ALB
  vs app 500s; (2) nginx error log: “upstream timed out” / “connect() failed”;
  (3) `NginxSample` active connections + requests by status; (4) the app's own
  transactions during the same window — healthy; (5) which location block
  proxies `/api/` and its timeout; (6) verdict.
- *Evidence checks:* the exact error-log phrase for the majority of failures;
  the percentage of 502s among `/api/` requests in the window (nearest 5%).
- *Case closed:* read an error's *layer* before its message; next steps —
  sane proxy timeouts, upstream health checks, alerting on nginx 5xx rate.

**I6 · One connection for the whole restaurant** (Postgres access pattern)
- *Symptom:* under a burst of orders everything slows uniformly; Postgres CPU
  is idle; no single query is slow.
- *Arm:* none needed for the underlying truth — `server/database.js` uses a
  single pg `Client`. Arm only the *load*: `DEMO_DB_BURST` (a traffic script
  placing concurrent orders for N minutes) or run during the load-testing
  setup in `docs/LOAD_TESTING.md`.
- *Chain:* (1) APM: response time climbs, throughput flat-ceilinged; (2)
  time-in-database dominates but per-query durations are normal; (3)
  `pg_stat_activity` (the nri-postgresql custom metrics already emit
  `active_connections` / `idle_connections`): active connections pinned at
  **1**; (4) Postgres host metrics rule out CPU/IO; (5) the code: one `Client`,
  queries serialise; (6) verdict — the bottleneck is the *shape* of the
  connection, and the fix is a `Pool` with a deliberate size.
- *Evidence checks:* the pinned active-connection count (exactly 1); the
  approximate throughput ceiling during the burst.
- *Case closed:* a queue is not a slow query; next steps — pool sizing,
  connection metrics on the dashboard, load test before/after.

**I7 · The table is locked** (Postgres locks)
- *Symptom:* placing an order hangs; browsing menus is fine; DB CPU ~0.
- *Arm:* `DEMO_DB_LOCK` — a helper transaction that updates a row in
  `orders` and sleeps uncommitted for a set window (started/stopped like the
  other switches; the container entrypoint or a small admin endpoint runs it).
- *Chain:* (1) only writes hang — reads fine (rules out general DB trouble);
  (2) transaction time is *wait*, not work; (3) lock metrics — the integration
  config already sets `COLLECT_DB_LOCK_METRICS: true`: ungranted locks appear;
  (4) identify the blocked PID and what it's waiting on; (5) identify the
  **blocking** PID and its state (`idle in transaction`); (6) verdict + the
  safe interventions (commit/rollback, `pg_terminate_backend`) and why you
  check before you kill.
- *Evidence checks:* the blocking PID (exact); the lock type/mode waited on.
- *Case closed:* next steps — statement/lock timeouts, transaction hygiene,
  alerting on lock waits, never leave a transaction open across user think-time.

**I8 · The slow lookup** (missing index)
- *Symptom:* the Orders lookup has been getting slower for weeks; everything
  else is fine.
- *Arm:* `DEMO_DB_BIG_ORDERS` — seed `orders`/`order_items` with synthetic
  history (idempotent seed script, clearly synthetic customers) so the lookup
  column (the one the Orders page searches by) is large and unindexed.
- *Chain:* (1) slowest query by total time, not by count; (2) its text — one
  query, big table; (3) rows examined vs returned (sequential scan evidence
  via the Postgres query-performance data); (4) the table's growth over time;
  (5) the fix: `CREATE INDEX` on the lookup column; (6) re-run the same
  widgets — scan gone, duration collapses; the *verification is a checkpoint*,
  judged from the new duration bucket.
- *Evidence checks:* the top query's share of total DB time (nearest 10%);
  post-index duration bucket.
- *Case closed:* next steps — index for the queries you actually run, watch
  top-by-total-time weekly, seed data in demos must mimic production volume.

**I9 (stretch) · The bloated table** (Postgres maintenance)
- *Symptom:* disk and table size grow while order count doesn't; autovacuum
  can't keep up under churn. Arm: `DEMO_DB_CHURN` (bulk update/delete cycles
  against a synthetic slice). Evidence: bloat metrics (already collected),
  dead-tuple counts, last-vacuum timestamps. Evidence check: dead tuples as a
  multiple of live rows. Case closed: vacuum/analyze, autovacuum tuning —
  maintenance as an observability topic, not a mystery.

### 11.3 Build order (extends §9)

9. I2 + I3 ports first (they reuse Mission 3/4 surfaces and existing callouts).
10. I5 (nginx) — needs only the timeout switch and log-derived widgets.
11. I6 during a scheduled load test (no new fault code; needs the burst script).
12. I7 + I8 (DB switches + seed script).
13. I1 + I4 ports, then I9 if wanted.
14. Evidence Board pages (§8 extension) alongside each, not after all.

### 11.4 Acceptance tests (extends §10)

- **A9** With exactly one investigation armed, the §7 banner names it, its
  page is completable end-to-end, and its evidence checks reject values from
  a *different* window or incident.
- **A10** With nothing armed, every investigation page renders its “not live
  right now” state and records no answers.
- **A11** I6's pinned-connection evidence is visible in the account's own data
  (active_connections = 1 during burst) before the investigation ships — if
  the app is later moved to a Pool, I6 must be re-armed or retired, and the
  page copy says so.
- **A12** I7's lock helper cannot outlive its window: after the window, no
  ungranted locks remain and order placement is normal.
- **A13** Each investigation's Evidence Board page shows its fault during the
  armed window and is visibly quiet outside it.
