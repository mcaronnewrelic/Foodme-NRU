#!/usr/bin/env bash
# Creates an alert policy for FoodMe with two conditions, unless they exist (by exact name):
#   - Menu failed to load:  any server error on GET /api/restaurant/by-name/:name. This is the condition the
#                           planned failure (DEMO_FAILING_RESTAURANT) trips.
#   - Order failed:         any server error on POST /api/order.
# Both fire on one error in a 5-minute window and close once the errors stop. An email destination, channel and
# workflow send each issue when it opens and when it closes.
#
#   NEW_RELIC_API_KEY=NRAK-... bash newrelic/alerts.sh
#
# Environment (all optional):
#   ALERT_EMAIL  who gets the email. Only used when the destination is created here. Default: demo@newrelicuniversity.com.
# GraphQL is single-quoted on purpose: its $names are GraphQL variables, not shell ones.
# shellcheck disable=SC2016
source "$(dirname "$0")/lib.sh"

ALERT_EMAIL="${ALERT_EMAIL:-demo@newrelicuniversity.com}"

POLICY_NAME='FoodMe - Menus and orders'
DESTINATION_NAME='FoodMe alert email'
CHANNEL_NAME='FoodMe alert email'
WORKFLOW_NAME='FoodMe - Menu and order alerts'
MENU='WebTransaction/Expressjs/GET//api/restaurant/by-name/:name'
ORDER='WebTransaction/Expressjs/POST//api/order'

account_vars() { jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg name "$1" '{account: $account, name: $name}'; }

# ---- Alert policy -----------------------------------------------------------------------------------------

policy_id="$(nerdgraph 'query($account: Int!, $name: String!) { actor { account(id: $account) { alerts {
    policiesSearch(searchCriteria: {name: $name}) { policies { id name } } } } } }' "$(account_vars "$POLICY_NAME")" \
  | jq -r --arg name "$POLICY_NAME" '[.actor.account.alerts.policiesSearch.policies[] | select(.name == $name) | .id][0] // empty')"
if [[ -n "$policy_id" ]]; then
  log "Alert policy exists, skipped: $POLICY_NAME ($policy_id)"
else
  policy_id="$(nerdgraph 'mutation($account: Int!, $policy: AlertsPolicyInput!) {
      alertsPolicyCreate(accountId: $account, policy: $policy) { id name } }' \
    "$(jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg name "$POLICY_NAME" \
      '{account: $account, policy: {name: $name, incidentPreference: "PER_CONDITION_AND_TARGET"}}')" | jq -r '.alertsPolicyCreate.id')"
  log "Alert policy created: $POLICY_NAME ($policy_id)"
fi

# create_condition NAME NRQL_QUERY
# One error in a 5-minute window opens it. A missing minute counts as 0, so the incident closes by itself.
create_condition() {
  local name="$1" query="$2" condition_id
  condition_id="$(nerdgraph 'query($account: Int!, $policy: ID!, $name: String!) { actor { account(id: $account) { alerts {
      nrqlConditionsSearch(searchCriteria: {policyId: $policy, name: $name}) { nrqlConditions { id name } } } } } }' \
    "$(jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg policy "$policy_id" --arg name "$name" '{account: $account, policy: $policy, name: $name}')" \
    | jq -r --arg name "$name" '[.actor.account.alerts.nrqlConditionsSearch.nrqlConditions[] | select(.name == $name) | .id][0] // empty')"
  if [[ -n "$condition_id" ]]; then
    log "Alert condition exists, skipped: $name ($condition_id)"
    return
  fi
  condition_id="$(nerdgraph 'mutation($account: Int!, $policy: ID!, $condition: AlertsNrqlConditionStaticInput!) {
      alertsNrqlConditionStaticCreate(accountId: $account, policyId: $policy, condition: $condition) { id name } }' \
    "$(jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg policy "$policy_id" --arg name "$name" --arg query "$query" '{
      account: $account, policy: $policy,
      condition: {
        name: $name, enabled: true, nrql: {query: $query},
        signal: {aggregationWindow: 60, aggregationMethod: "EVENT_FLOW", aggregationDelay: 120, fillOption: "STATIC", fillValue: 0},
        terms: [{threshold: 0, operator: "ABOVE", thresholdDuration: 300, thresholdOccurrences: "AT_LEAST_ONCE", priority: "CRITICAL"}],
        violationTimeLimitSeconds: 86400
      }}')" | jq -r '.alertsNrqlConditionStaticCreate.id')"
  log "Alert condition created: $name ($condition_id)"
}

create_condition 'Menu failed to load' \
  "SELECT count(*) FROM TransactionError WHERE appName = 'FoodMe' AND transactionName = '$MENU'"
create_condition 'Order failed' \
  "SELECT count(*) FROM TransactionError WHERE appName = 'FoodMe' AND transactionName = '$ORDER'"

# ---- Email: destination, channel, then a workflow for this policy ---------------------------------------------

destination_id="$(nerdgraph 'query($account: Int!, $name: String!) { actor { account(id: $account) { aiNotifications {
    destinations(filters: {name: $name, type: EMAIL}) { entities { id name } } } } } }' "$(account_vars "$DESTINATION_NAME")" \
  | jq -r --arg name "$DESTINATION_NAME" '[.actor.account.aiNotifications.destinations.entities[] | select(.name == $name) | .id][0] // empty')"
if [[ -n "$destination_id" ]]; then
  log "Email destination exists, reused: $DESTINATION_NAME ($destination_id)"
else
  destination_id="$(nerdgraph 'mutation($account: Int!, $destination: AiNotificationsDestinationInput!) {
      aiNotificationsCreateDestination(accountId: $account, destination: $destination) { destination { id name } } }' \
    "$(jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg name "$DESTINATION_NAME" --arg email "$ALERT_EMAIL" \
      '{account: $account, destination: {type: "EMAIL", name: $name, properties: [{key: "email", value: $email}]}}')" \
    | jq -r '.aiNotificationsCreateDestination.destination.id // empty')"
  [[ -n "$destination_id" ]] || { log "Creating the email destination failed."; exit 1; }
  log "Email destination created: $DESTINATION_NAME -> $ALERT_EMAIL ($destination_id)"
fi

channel_id="$(nerdgraph 'query($account: Int!, $name: String!) { actor { account(id: $account) { aiNotifications {
    channels(filters: {name: $name}) { entities { id name } } } } } }' "$(account_vars "$CHANNEL_NAME")" \
  | jq -r --arg name "$CHANNEL_NAME" '[.actor.account.aiNotifications.channels.entities[] | select(.name == $name) | .id][0] // empty')"
if [[ -n "$channel_id" ]]; then
  log "Email channel exists, reused: $CHANNEL_NAME ($channel_id)"
else
  channel_id="$(nerdgraph 'mutation($account: Int!, $channel: AiNotificationsChannelInput!) {
      aiNotificationsCreateChannel(accountId: $account, channel: $channel) { channel { id name } } }' \
    "$(jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg name "$CHANNEL_NAME" --arg destination "$destination_id" \
      '{account: $account, channel: {type: "EMAIL", name: $name, destinationId: $destination, product: "IINT", properties: []}}')" \
    | jq -r '.aiNotificationsCreateChannel.channel.id // empty')"
  [[ -n "$channel_id" ]] || { log "Creating the email channel failed."; exit 1; }
  log "Email channel created: $CHANNEL_NAME ($channel_id)"
fi

workflow_id="$(nerdgraph 'query($account: Int!, $name: String!) { actor { account(id: $account) { aiWorkflows {
    workflows(filters: {name: $name}) { entities { id name } } } } } }' "$(account_vars "$WORKFLOW_NAME")" \
  | jq -r --arg name "$WORKFLOW_NAME" '[.actor.account.aiWorkflows.workflows.entities[] | select(.name == $name) | .id][0] // empty')"
if [[ -n "$workflow_id" ]]; then
  log "Alert workflow exists, skipped: $WORKFLOW_NAME ($workflow_id)"
else
  result="$(nerdgraph 'mutation($account: Int!, $workflow: AiWorkflowsCreateWorkflowInput!) {
      aiWorkflowsCreateWorkflow(accountId: $account, createWorkflowData: $workflow) { workflow { id name } errors { description type } } }' \
    "$(jq -n --argjson account "$NEW_RELIC_ACCOUNT_ID" --arg name "$WORKFLOW_NAME" --arg policy "$policy_id" --arg channel "$channel_id" '{
      account: $account,
      workflow: {
        name: $name, workflowEnabled: true, destinationsEnabled: true, enrichmentsEnabled: false,
        mutingRulesHandling: "NOTIFY_ALL_ISSUES",
        issuesFilter: {name: $name, type: "FILTER",
          predicates: [{attribute: "labels.policyIds", operator: "EXACTLY_MATCHES", values: [$policy]}]},
        destinationConfigurations: [{channelId: $channel, notificationTriggers: ["ACTIVATED", "CLOSED"]}]
      }}')")"
  check_result "$result" '.aiWorkflowsCreateWorkflow'
  log "Alert workflow created: $WORKFLOW_NAME ($(jq -r '.aiWorkflowsCreateWorkflow.workflow.id' <<<"$result"))"
fi
