#!/usr/bin/env bash
# Creates the "FoodMe" workload, unless it exists: the browser app, the APM app, and every dashboard and
# service level named "FoodMe…" (found by search, so recreating one later adds it back automatically).
#
#   NEW_RELIC_API_KEY=NRAK-... bash newrelic/workload.sh
#
# Environment (all optional):
#   BROWSER_ENTITY_GUID  default: the FoodMe browser app
#   APM_ENTITY_GUID      default: the FoodMe APM app
# GraphQL is single-quoted on purpose: its $names are GraphQL variables, not shell ones.
# shellcheck disable=SC2016
source "$(dirname "$0")/lib.sh"

WORKLOAD_NAME='FoodMe'
BROWSER_ENTITY_GUID="${BROWSER_ENTITY_GUID:-MTM1MjgxMXxCUk9XU0VSfEFQUExJQ0FUSU9OfDkzMjM5Nzg4}"
APM_ENTITY_GUID="${APM_ENTITY_GUID:-MTM1MjgxMXxBUE18QVBQTElDQVRJT058OTI2MzIxNzQ}"

guid="$(entity_guid "$WORKLOAD_NAME" "type = 'WORKLOAD'")"
if [[ -n "$guid" ]]; then
  log "Workload exists, skipped: $WORKLOAD_NAME ($guid)"
  exit 0
fi

result="$(nerdgraph 'mutation($account: Int!, $workload: WorkloadCreateInput!) {
    workloadCreate(accountId: $account, workload: $workload) { guid name } }' \
  "$(jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg name "$WORKLOAD_NAME" \
    --arg browser "$BROWSER_ENTITY_GUID" --arg apm "$APM_ENTITY_GUID" '{
      account: $account,
      workload: {
        name: $name,
        entityGuids: [$browser, $apm],
        entitySearchQueries: [
          {query: "type = '\''DASHBOARD'\'' AND name LIKE '\''FoodMe%'\''"},
          {query: "type = '\''SERVICE_LEVEL'\'' AND name LIKE '\''FoodMe%'\''"}
        ],
        scopeAccounts: {accountIds: [$account]}
      }}')")"
log "Workload created: $WORKLOAD_NAME ($(jq -r '.workloadCreate.guid' <<<"$result"))"
