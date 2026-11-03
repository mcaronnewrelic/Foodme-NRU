# New Relic Demo Features

FoodMe is also a teaching app for New Relic. This page covers the parts built for that: the "Behind the scenes" callouts, the planned failures students can find, source maps, and the setup scripts. For installing the agents themselves, see [New Relic Infrastructure Setup](./NEW_RELIC_INFRA_SETUP.md) and [New Relic Integrations](./NEW_RELIC_INTEGRATIONS_SETUP.md).

## Behind the scenes callouts

Green dashed boxes on the pages show the New Relic data that page creates, with the NRQL and a button that opens it in New Relic.

| Page | What the callout shows |
|---|---|
| Customer | `enduser.id`, set by `setUserId()` |
| Restaurants | The `GET /api/restaurant` transaction |
| Menu | Each menu request, and the same requests by status code |
| Checkout | Recent `POST /api/order` transactions |
| Thank you | The order Transaction, `ItemsOrdered` detail events, an `orderId` JOIN, and global/per-restaurant total metrics |
| Orders | Order lookups, without any email address |
| How It Works | The simulated error, its page action, and its round-trip time |

**Show or hide them** with "Behind the scenes" in the header. The choice is saved in the browser. They start hidden; change `CALLOUTS_SHOWN_BY_DEFAULT` in `angular-app/src/app/nr-config.ts` to start shown.

**Add one** to any page:

```html
<app-nr-callout title="Short title" [nrql]="myNrql" buttonLabel="See it">
  One or two sentences about what this data is.
</app-nr-callout>
```

Import `NrCalloutComponent` in the page's component and define `myNrql` as a property. Add `[showBrowserErrors]="true"` for a second button that opens Errors Inbox for the browser app.

**How the links are built.** The Angular app asks the server for `GET /api/nr-config`, which returns the account ID and browser entity GUID from `.env`. Nothing New Relic specific is stored in the Angular code. The buttons open in one shared tab named `newrelic`. That endpoint is ignored by the APM agent (`rules.ignore` in `server/newrelic.js`), so it doesn't show up as a transaction.

## Order telemetry trade-offs

The server returns `orderId` only after accepting an order. Database mode uses the
database-generated ID; JSON demo mode generates a UUID. The receipt shows that ID
and the cart's line items. `requestId` remains an HTTP/log correlation identifier,
not the receipt or item-event join key.

- **Custom attributes:** the existing checkout Transaction holds `orderId`,
  `customer`, `restaurant`, `itemCount`, `orderTotal`, and `demoCode` alongside
  duration and HTTP status. Failed checkouts retain their business context but
  have no accepted `orderId`.
- **Custom events:** one `ItemsOrdered` event per cart line holds `orderId`,
  `itemName`, `itemCount` (quantity), `unitPrice`, `itemTotal`, and `demoCode`.
  Item events are emitted after acceptance and do not repeat the customer,
  restaurant, or order total. More lines mean more event ingest.
- **Custom metrics:** each accepted order records its decimal total with
  `recordMetric('total', total)` and `recordMetric('<restaurant-slug>/total', total)`.
  The Node agent adds `Custom/` automatically. A total timeslice already includes
  a count, so a separate count metric is redundant. Query each global or
  restaurant series separately to avoid double-counting revenue.

For the same time window, the global metric has one name and the restaurant
breakdown has at most one name per restaurant receiving an order. Using order IDs,
request IDs, or customer codes in metric names would create continually growing
cardinality. Rollups retain aggregate totals and counts but discard individual
orders and reduce time resolution. They do not require discarding cents. Lower
data volume is not a universal pricing guarantee; cost depends on the plan.

An item-to-order JOIN (replace the example ID with the receipt's ID):

```sql
FROM ItemsOrdered
JOIN (
  FROM Transaction
  SELECT orderId, customer, restaurant, orderTotal, duration, http.statusCode
  WHERE appName = 'OrderUp'
    AND name = 'WebTransaction/Expressjs/POST//api/order'
    AND orderId = 'example-order-id'
  LIMIT MAX
) ON orderId
SELECT orderId, customer, restaurant, itemName, itemCount, unitPrice,
       itemTotal, orderTotal, duration, http.statusCode
WHERE orderId = 'example-order-id'
SINCE 1 day ago LIMIT MAX
```

Order IDs are strings on both sides because NRQL JOINs do not coerce types.
The outer item rows join to the one parent checkout Transaction. Do not sum
`orderTotal` across detail rows: it repeats for every item. Use `itemTotal` for
line-item totals. Transaction sampling and independent ingestion can leave an
inner JOIN temporarily incomplete or permanently without a sampled parent.
The dashboard's Transaction counts are also subject to APM event sampling.

The old `Order` event and `Custom/Orders/*` metrics are no longer emitted. Existing
historical data remains in New Relic; deploy the updated dashboard definition to
change its queries. No live dashboard or account configuration is changed by a
local source edit.

## Settings

All in `.env` (see `.env.example`).

| Variable | Needed for |
|---|---|
| `NEW_RELIC_ACCOUNT_ID` | Callout buttons. Without it, the buttons are hidden. |
| `NEW_RELIC_BROWSER_ENTITY_GUID` | The "Open Errors Inbox" button. Find it as `entityGuid` on any `PageAction` event. |
| `NEW_RELIC_BROWSER_APP_ID` | Uploading source maps. Find it as `appId` on any `PageAction` event. |
| `DEMO_FAILING_RESTAURANT` | Planned failure: this restaurant's menu fails. |
| `DEMO_FAILING_ORDER_RESTAURANT` | Planned failure: orders from this restaurant fail. |
| `DEMO_FAILING_ORDER_ITEM` | Planned failure: orders containing this menu item fail. |

Restaurant and item values are slugs: lowercase, punctuation dropped, underscores for spaces (`Esther's German Saloon` becomes `esthers_german_saloon`). Leave a failure variable empty to turn it off. The container reads `.env` only when it is created, so after changing a value run:

```bash
docker-compose -f docker/docker-compose.dev-simple.yml up -d --build --force-recreate foodme
```

## Planned failures

| Switch | What visitors see | What students can find |
|---|---|---|
| `DEMO_FAILING_RESTAURANT` | "Failed to load restaurant menu" | A 500 on `GET /api/restaurant/by-name/:name` for one `restaurantSlug`, with the message `Menu data ... is corrupted` |
| `DEMO_FAILING_ORDER_RESTAURANT` | "Purchase failed" for every order from that restaurant | `Kitchen at "..." is not accepting orders` on `POST /api/order`, with the restaurant on the transaction |
| `DEMO_FAILING_ORDER_ITEM` | "Purchase failed" when the cart has that item | `Inventory check failed for "..."` and a `failedItem` attribute. Harder to spot: only some orders fail. |

A failed order emits no `ItemsOrdered` events or sales metrics. A database write
failure is returned as an error rather than a successful fallback receipt.

A path for students: the status-code callout on the Menu page shows one URL with a 500, `FROM TransactionError WHERE restaurantSlug IS NOT NULL` shows the message, the trace shows where it failed, and Errors Inbox shows how the error is grouped.

## Errors reach one handler

Route handlers pass failures to Express with `next(error)`, and the global error handler at the end of `server/index.js` answers with JSON and an `X-Error-ID` header. Two rules keep New Relic accurate:

- Don't send your own 500 and also call `noticeError`. The agent adds an `HttpError 500` of its own, so you get two errors per failure.
- Keep the error handler registered after every route. Express only sends an error to handlers registered later than the route that failed.

## Source maps

Angular already builds `.map` files into `dist/browser`. New Relic needs them uploaded for each JavaScript file, named by the URL the browser loads. File names are hashed, so upload after every build:

```bash
npm run build:angular
npm run sourcemaps:upload            # uses http://localhost
scripts/upload-sourcemaps.sh https://your-site.example.com
```

It needs `NEW_RELIC_API_KEY` (a User key) and `NEW_RELIC_BROWSER_APP_ID` in `.env`. Errors that happened before an upload keep showing "Source map not detected".

## Dashboards, service levels and alerts

The `newrelic/` folder creates a dashboard, service levels, alerts and a workload through the NerdGraph API, and the **New Relic setup** GitHub workflow runs it. See [newrelic/README.md](../newrelic/README.md).
