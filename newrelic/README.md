# New Relic setup scripts

These scripts create what FoodMe needs in New Relic, using the NerdGraph (GraphQL) API. Each one looks up every item by its exact name first and **creates only what is missing**. Nothing is ever updated or deleted.

That makes them safe to run any time. If someone changes one of these items by hand, delete it in New Relic and run the script again to get the original back.

| Script | Creates |
|---|---|
| `dashboards.sh` | Every dashboard in `dashboards/*.json` |
| `service-levels.sh` | Success and latency service levels for the APM app and the browser app |
| `alerts.sh` | An alert policy with two conditions, plus an email destination, channel and workflow |
| `workload.sh` | The **FoodMe** workload: the browser app, the APM app, and the dashboards and service levels above |
| `setup.sh` | All four, in that order |

## What gets created

| Name | Type | Notes |
|---|---|---|
| FoodMe Overview | Dashboard | Three pages: Orders, Menus and errors, Browser. From `dashboards/foodme-overview.json`. The queries match the "Behind the scenes" callouts on the site. |
| FoodMe Menu - Success | Service level (APM app) | 99% of menu requests end without a server error, over 7 days. **Includes** the planned menu failure, because that is what it measures. |
| FoodMe Checkout - Latency | Service level (APM app) | 95% of `POST /api/order` requests are answered in under 0.5 seconds |
| FoodMe API - Success | Service level (APM app) | 99% of web requests end without an unexpected error. Leaves out `/simulate/*`. |
| FoodMe Browser - Latency (LCP) | Service level (browser app) | 95% of page loads have a Largest Contentful Paint under 2.5 seconds |
| FoodMe Browser - Availability (AJAX) | Service level (browser app) | 99% of AJAX requests get an answer (not a 5xx or a network failure). Leaves out `/simulate/*`. |
| FoodMe - Menus and orders | Alert policy | One incident per condition and target |
| Menu failed to load | NRQL alert condition | Fires on any `TransactionError` for `GET /api/restaurant/by-name/:name` within 5 minutes. This is the one the planned failure trips. |
| Order failed | NRQL alert condition | Fires on any `TransactionError` for `POST /api/order` within 5 minutes |
| FoodMe alert email | Email destination and channel | Sends to `ALERT_EMAIL` |
| FoodMe - Menu and order alerts | Alert workflow | Emails every issue from the policy, when it opens and when it closes |
| FoodMe | Workload | The browser app, the APM app, and any dashboard or service level named `FoodMe…` |

The deliberate failures are treated in two ways. The `/simulate/*` routes and the how-it-works error button are left out of the success service levels and the alerts, because they fail on purpose and constantly. The planned menu failure (`DEMO_FAILING_RESTAURANT` in `.env`) is deliberately **kept in**, so the menu service level drops and the menu alert fires when students visit that restaurant.

## Run it

You need `bash`, `curl` and `jq`. You also need a New Relic **User key** (`NRAK-...`) with permission to create dashboards, alerts, service levels and workloads. The `NEW_RELIC_API_KEY` secret the deploy workflows use is one.

```bash
export NEW_RELIC_API_KEY=NRAK-...
bash newrelic/setup.sh            # everything
bash newrelic/alerts.sh           # or just one part
```

On GitHub, the **New Relic setup** workflow runs the same scripts. Run it from the Actions tab, where you can pick one part. It also runs by itself when anything in `newrelic/` changes on `main`.

## Settings

All optional, as environment variables. On GitHub, set the account and alert email as the repository variables `NEW_RELIC_ACCOUNT_ID` and `NEW_RELIC_ALERT_EMAIL`.

| Variable | Default | Used by |
|---|---|---|
| `NEW_RELIC_ACCOUNT_ID` | `1352811` | all; dashboard queries are pointed at this account |
| `NERDGRAPH_URL` | `https://api.newrelic.com/graphql` | all; EU accounts use `https://api.eu.newrelic.com/graphql` |
| `ALERT_EMAIL` | `demo@newrelicuniversity.com` | `alerts.sh` |
| `BROWSER_ENTITY_GUID`, `APM_ENTITY_GUID` | the FoodMe apps in account 1352811 | `service-levels.sh`, `workload.sh` |

When you move to another account, also change `NEW_RELIC_ACCOUNT_ID`, `NEW_RELIC_BROWSER_ENTITY_GUID` and `NEW_RELIC_BROWSER_APP_ID` in `.env`, and set `BROWSER_ENTITY_GUID` and `APM_ENTITY_GUID` for these scripts. The default GUIDs belong to account 1352811.

Because existing items are never changed, a setting only applies to items the script creates. To send alerts to a new address, delete the **FoodMe alert email** destination in New Relic (its channel and workflow with it, if New Relic asks), then run `alerts.sh` with the new `ALERT_EMAIL`.

## Changing what gets created

- **A dashboard:** edit its JSON in `dashboards/` (export it from New Relic, or edit by hand), then delete the dashboard in New Relic and run `dashboards.sh`.
- **Names:** the workload finds dashboards and service levels by their `FoodMe` prefix. Keep it when renaming.
