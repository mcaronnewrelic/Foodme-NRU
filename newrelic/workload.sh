#!/usr/bin/env bash
# Creates the "OrderUp" workload, unless it exists: the browser app, the APM app, and every dashboard and
# service level named "OrderUp…" (found by search, so recreating one later adds it back automatically).
#
#   NEW_RELIC_API_KEY=NRAK-... bash newrelic/workload.sh
#
# Environment (all optional):
#   BROWSER_ENTITY_GUID  default: the OrderUp browser app
#   APM_ENTITY_GUID      default: the OrderUp APM app
# GraphQL is single-quoted on purpose: its $names are GraphQL variables, not shell ones.
# shellcheck disable=SC2016
source "$(dirname "$0")/lib.sh"

WORKLOAD_NAME='OrderUp'
BROWSER_ENTITY_GUID="${BROWSER_ENTITY_GUID:-$(entity_guid 'OrderUp' "domain = 'BROWSER' AND type = 'APPLICATION'")}"
APM_ENTITY_GUID="${APM_ENTITY_GUID:-$(entity_guid 'OrderUp' "domain = 'APM' AND type = 'APPLICATION'")}"

# The entities must exist before their service levels / workload can be
# created: deploy the renamed app once so it reports, then run setup.
if [[ -z "$BROWSER_ENTITY_GUID" || -z "$APM_ENTITY_GUID" ]]; then
  log "Could not find the OrderUp APM/browser entities by name - has the renamed app reported to New Relic yet?"
  exit 1
fi

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
          {query: "type = '\''DASHBOARD'\'' AND name LIKE '\''OrderUp%'\''"},
          {query: "type = '\''SERVICE_LEVEL'\'' AND name LIKE '\''OrderUp%'\''"}
        ],
        scopeAccounts: {accountIds: [$account]}
      }}')")"
log "Workload created: $WORKLOAD_NAME ($(jq -r '.workloadCreate.guid' <<<"$result"))"
