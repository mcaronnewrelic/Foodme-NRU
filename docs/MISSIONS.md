# The Missions — instructor & maintainer guide

OrderUp's ordering flow doubles as a five-mission observability exercise.
Turn on **Behind the scenes** (the header toggle, or add `?callouts=1` to
any URL) and every page gains a callout that runs the same loop:

- **Try it** — one concrete action in the app.
- **Learn it** — what data that action just created, and why.
- **Find it** — one click opens that exact data in New Relic.
- **Check yourself** — one question per stop, answered from the data.

A progress strip across the top names the current mission and shows the
five stops; the **Your journey** block on How It Works recaps state and,
at 5 of 5, shows the completion block. None of this exists in customer
mode — missions are a Behind-the-scenes-only layer over the unchanged
ordering flow.

Students need nothing but the app: the path is self-explanatory in situ.
This document is for the other two audiences — instructors planning a
session, and maintainers changing the code — because the parts that
matter to them (the map, the answer keys, the plumbing) are deliberately
invisible to students.

## The five missions

| # | Mission | Page | What it teaches | Find data | Check |
|---|---------|------|-----------------|-----------|-------|
| 1 | Say who you are | Customer | `setUserId()` makes the name the `enduser.id`; a second stamp, the `demoCode`, rides every browser event | Personal — faceted by `demoCode` | Evidence (choice): how many event types carry your code so far |
| 2 | Find a menu in the data | Restaurants → Menu | Every menu load is an APM transaction; filtering the list is client-side and creates **no** request — the absence is the lesson | Cohort — labelled "Shows everyone's data" | Reasoning (choice): why no new request appeared |
| 3 | Place the order, keep the receipt | Checkout → Thank You | One order is three records — an `Order` custom event, a `POST /api/order` transaction, `Custom/Orders/*` metrics — stitched by one `requestId` | Personal — scoped by `requestId` | Evidence (text): the last 4 characters of this order's `requestId` |
| 4 | Find it again later | Orders | Lookup works with no email; `requestId` and `demoCode` are the join keys — and the transaction's `userID` is the code in disguise | Personal — filtered by `userID` | Reasoning (multi-select): which two values identify your order |
| 5 | Break it on purpose | How It Works | One click, three traces (JavaScriptError, PageAction, round-trip time); then hunting a planted failure to its exact error message | Personal + cohort errors | Evidence (text): the simulated error's `errorType` — or the armed failure's exact message (either half completes the mission) |

## Answer keys, and where they come from

Read this before changing any of the code named here — several keys are
not where you'd first look.

- **Mission 1** is judged against `EventTypesService`
  (`angular-app/src/app/services/event-types.service.ts`). The app knows
  its own actions exactly, so it tracks the four faceted types itself:
  an HTTP interceptor marks `AjaxRequest`, route changes mark
  `PageView`, `NewRelicService.addPageAction` marks `PageAction` and
  `noticeError` marks `JavaScriptError` — persisted in localStorage
  (`orderup-event-types`). A fresh visitor reaches the Customer check at
  2; a detour through the error simulation makes it "3 or more". If you
  add a new `addPageAction` call early in the journey, expect the count
  to move.
- **Mission 2** is a static reasoning check; the behaviour it names
  (filtering is client-side) lives in `RestaurantsComponent`'s filter
  signals. Using a filter is also what marks the mission *tried*.
- **Mission 3** is judged against the Thank You page's own `requestId`
  (router state from checkout). Trivial to answer from the page,
  impossible to fake having placed the order. A solved check stays
  solved for later orders.
- **Mission 4**'s Find query filters on `userID`, which the server
  derives from the customer's name in `generateUserID`
  (`server/index.js`): `'user_' + name.toLowerCase().replace(/[^a-z0-9]/g, '_')`.
  The client mirrors that derivation from the demoCode to fill the
  callout's `<userId>` token. **If the server derivation changes, the
  query breaks silently** — change them together.
- **Mission 5, simulated half:** the sim writes `errorType: 'sync'`
  (`how-it-works.ts`, `simulateError()`).
- **Mission 5, armed half:** the key is built client-side from
  `/api/nr-config`'s `armedScenario` using the server's own message
  templates (`server/index.js`) — note the asymmetry: the menu failure
  embeds the route **slug** it was called with
  (`Menu data for "<slug>" is corrupted: menu_items.category is null for 3 rows`),
  while the order failures embed **display names**
  (`Kitchen at "<name>" is not accepting orders: ticket printer offline`,
  `Inventory check failed for "<item>": stock count is -2`).
  The weekly rotation changes the target — and therefore the key —
  every week; because the key is built at render time from the armed
  scenario, it follows automatically. The registry
  (`services/missions.ts`) gives Mission 5 an `altQuestionId`, so
  solving either half checks the mission.

All checks are judged client-side (the key ships with the question, as
on browser.nru.to). They are teaching checks, not exams.

## Identity, and why there is no email

Every visitor gets a session code, `OU-XXXX` (localStorage
`orderup-demo-code`), stamped on all browser-agent data via
`setCustomAttribute('demoCode', …)` on load and every route change
(`DemoIdentityService`). The sample customer's **name is the code**, so
the same value appears as `enduser.id` in browser data and — via the
server's derivation above — as `userID` on APM transactions. Email is
collected nowhere: in a shared demo account it would be a PII trap.
The sample phone sits in the reserved (503) 555-01xx range, and order
lookup is by that phone only.

## State and recorded data

- Progress lives in localStorage `orderup-missions`:
  `{ questions: { "<missionId>:<questionId>": { attempts, solved } },
     missions: { "<missionId>": { tried, found } } }`
  (`MissionProgressService`). *Tried* = the Try action was observed;
  *found* = a Find link on the mission's callout was clicked;
  *checked* = its check (or alternative) is solved. State is per
  browser — there is no cross-device progress.
- Every answer, right or wrong, fires a browser custom event
  **`OrderupQuizAnswer`** with `missionId`, `questionId`, `question`,
  `answer`, `outcome` (`correct`/`incorrect`), `attempt`, `demoPage`
  and `demoCode` — mirroring browser.nru.to's `DemoQuizAnswer` so the
  dashboard queries port directly. The local progress above is only
  the on-device view; the event stream is the record.
- The §8 follow-on (not yet built — see the spec) adds a
  knowledge-checks page over `OrderupQuizAnswer` to the scripted
  dashboards; the hub's completion block links the OrderUp Overview
  dashboard until that page exists.

## Instructor controls

- **Arming a failure.** One scenario is armed at almost all times.
  Resolution order (`server/demo-failures.js`): `DEMO_FAILING_*`
  environment > manual override (the panel at the top of How It
  Works, or `GET/POST/DELETE /api/demo/failures`, persisted on the
  instance) > a deterministic weekly rotation over the seed
  restaurants/items. The armed target is **deliberately exposed** —
  in `armedScenario`, the banner and the panel. Finding it is not
  the exercise; reproducing and tracing it is.
- **Forcing callouts for a class:** link or QR-code to any page with
  `?callouts=1`; it overrides the stored preference for that visit.

## Where the code lives

| Piece | Location |
|-------|----------|
| Mission registry (ids, titles, routes, check ids) | `angular-app/src/app/services/missions.ts` |
| Progress state (tried / found / attempts / solved) | `angular-app/src/app/services/mission-progress.service.ts` |
| Mission 1's event-type tracker | `angular-app/src/app/services/event-types.service.ts` |
| demoCode identity | `angular-app/src/app/services/demo-identity.service.ts` |
| Progress strip | `angular-app/src/app/components/mission-strip/` |
| Callout (Try line, Find-click → found, token resolution) | `angular-app/src/app/components/nr-callout/` |
| Check component (`choice` / `multi` / `number` / `text`) | `angular-app/src/app/components/nr-check/` |
| Per-mission wiring | the `customer`, `restaurants`, `menu`, `thank-you`, `orders`, `how-it-works` components |
| Failure scenarios & message templates | `server/demo-failures.js`, `server/index.js` |

The full design record — rationale, the link-pattern investigation,
and the unbuilt §8 dashboards and §11 Investigations — is
[the Try / Learn / Find / Check spec](./try-learn-find-spec.md).
For the callouts' history and the planned-failure scenarios as
originally sketched, see [NEW_RELIC_DEMO.md](./NEW_RELIC_DEMO.md).
