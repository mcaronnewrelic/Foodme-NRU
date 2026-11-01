#!/usr/bin/env bash
# Creates everything OrderUp needs in New Relic that is missing: the dashboard, service levels, alerts and the
# workload. Safe to run any number of times: existing items are left alone.
#
#   NEW_RELIC_API_KEY=NRAK-... bash newrelic/setup.sh
#
# Each step can also run on its own: dashboards.sh, service-levels.sh, alerts.sh, workload.sh.
# See newrelic/README.md.
set -euo pipefail
here="$(dirname "$0")"
bash "$here/dashboards.sh"
bash "$here/service-levels.sh"
bash "$here/alerts.sh"
# Last, so the workload's searches already find the dashboards and service levels.
bash "$here/workload.sh"
