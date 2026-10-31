#!/usr/bin/env bash
# Creates service levels for the FoodMe APM app and browser app, unless they exist (by exact name).
# Each has a 7-day rolling objective.
#
#   NEW_RELIC_API_KEY=NRAK-... bash newrelic/service-levels.sh
#
# Environment (all optional):
#   BROWSER_ENTITY_GUID  default: the FoodMe browser app
#   APM_ENTITY_GUID      default: the FoodMe APM app
#
# The success ones leave out the deliberate failures (/simulate/* and the how-it-works error button), so
# they show whether the site works rather than how often someone presses the button. The planned menu
# failure (DEMO_FAILING_RESTAURANT) is NOT left out: it is the error students are meant to find.
# GraphQL is single-quoted on purpose: its $names are GraphQL variables, not shell ones.
# shellcheck disable=SC2016
source "$(dirname "$0")/lib.sh"

BROWSER_ENTITY_GUID="${BROWSER_ENTITY_GUID:-MTM1MjgxMXxCUk9XU0VSfEFQUExJQ0FUSU9OfDkzMjM5Nzg4}"
APM_ENTITY_GUID="${APM_ENTITY_GUID:-MTM1MjgxMXxBUE18QVBQTElDQVRJT058OTI2MzIxNzQ}"
MENU='WebTransaction/Expressjs/GET//api/restaurant/by-name/:name'
ORDER='WebTransaction/Expressjs/POST//api/order'

# create_service_level ENTITY_GUID NAME DESCRIPTION TARGET VALID_JSON (good|bad) GOOD_OR_BAD_JSON
# VALID_JSON and GOOD_OR_BAD_JSON are {from, where} event queries.
create_service_level() {
  local entity="$1" name="$2" description="$3" target="$4" valid="$5" kind="$6" events="$7" guid result
  guid="$(entity_guid "$name" "type = 'SERVICE_LEVEL'")"
  if [[ -n "$guid" ]]; then log "Service level exists, skipped: $name ($guid)"; return; fi
  result="$(nerdgraph 'mutation($entity: EntityGuid!, $indicator: ServiceLevelIndicatorCreateInput!) {
      serviceLevelCreate(entityGuid: $entity, indicator: $indicator) { guid name } }' \
    "$(jq -n --arg entity "$entity" --arg name "$name" --arg description "$description" --argjson target "$target" \
      --argjson account "$NEW_RELIC_ACCOUNT_ID" --argjson valid "$valid" --arg kind "$kind" --argjson events "$events" '{
        entity: $entity,
        indicator: {
          name: $name, description: $description,
          events: ({accountId: $account, validEvents: $valid} + {("\($kind)Events"): $events}),
          objectives: [{target: $target, timeWindow: {rolling: {count: 7, unit: "DAY"}}}]
        }}')")"
  log "Service level created: $name ($(jq -r '.serviceLevelCreate.guid' <<<"$result"))"
}

query() { jq -n --arg from "$1" --arg where "$2" '{from: $from, where: $where}'; }

# ---- APM: the Node server's web requests ---------------------------------------------------------------

apm_web="entityGuid = '$APM_ENTITY_GUID' AND transactionType = 'Web' AND name NOT LIKE '%/simulate/%'"

create_service_level "$APM_ENTITY_GUID" 'FoodMe Menu - Success' \
  'Menu requests that end without a server error. Includes the planned menu failure, which is what this measures.' 99 \
  "$(query Transaction "entityGuid = '$APM_ENTITY_GUID' AND name = '$MENU'")" bad \
  "$(query TransactionError "entityGuid = '$APM_ENTITY_GUID' AND transactionName = '$MENU' AND error.expected IS FALSE")"

create_service_level "$APM_ENTITY_GUID" 'FoodMe Checkout - Latency' \
  'Orders the server accepts in under half a second.' 95 \
  "$(query Transaction "entityGuid = '$APM_ENTITY_GUID' AND name = '$ORDER'")" good \
  "$(query Transaction "entityGuid = '$APM_ENTITY_GUID' AND name = '$ORDER' AND duration < 0.5")"

create_service_level "$APM_ENTITY_GUID" 'FoodMe API - Success' \
  "Web requests that end without an unexpected error. Leaves out /simulate/*, which fails on purpose." 99 \
  "$(query Transaction "$apm_web")" bad \
  "$(query TransactionError "entityGuid = '$APM_ENTITY_GUID' AND error.expected IS FALSE AND transactionName NOT LIKE '%/simulate/%'")"

# ---- Browser: what visitors' browsers see ----------------------------------------------------------------

create_service_level "$BROWSER_ENTITY_GUID" 'FoodMe Browser - Latency (LCP)' \
  'Page loads whose Largest Contentful Paint is under 2.5 seconds (the "good" Core Web Vitals threshold).' 95 \
  "$(query PageViewTiming "entityGuid = '$BROWSER_ENTITY_GUID' AND timingName = 'largestContentfulPaint'")" good \
  "$(query PageViewTiming "entityGuid = '$BROWSER_ENTITY_GUID' AND timingName = 'largestContentfulPaint' AND largestContentfulPaint < 2.5")"

browser_ajax="entityGuid = '$BROWSER_ENTITY_GUID' AND requestUrl NOT LIKE '%/simulate/%'"
create_service_level "$BROWSER_ENTITY_GUID" 'FoodMe Browser - Availability (AJAX)' \
  'AJAX requests from the pages that get an answer (not a 5xx or a network failure). Leaves out /simulate/*, which fails on purpose.' 99 \
  "$(query AjaxRequest "$browser_ajax")" bad \
  "$(query AjaxRequest "$browser_ajax AND (httpResponseCode >= 500 OR httpResponseCode = 0)")"
