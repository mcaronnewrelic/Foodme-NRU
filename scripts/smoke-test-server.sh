#!/usr/bin/env bash
# Starts the server in a throwaway Node container and checks that its main routes still answer.
# Use it after changing the Node version or any server dependency.
#
#   scripts/smoke-test-server.sh            # Node 24 (default)
#   NODE_IMAGE=node:22 scripts/smoke-test-server.sh
#   SERVER_DIR=/tmp/server-copy scripts/smoke-test-server.sh   # try a changed package.json elsewhere
#
# It installs server/package.json into a copy inside the container, so your files and node_modules are
# untouched, and it runs without a database (the server falls back to its JSON data) and with the
# New Relic agent switched off.
set -euo pipefail

cd "$(dirname "$0")/.."
NODE_IMAGE="${NODE_IMAGE:-node:24}"
SERVER_DIR="${SERVER_DIR:-$PWD/server}"

docker run --rm -v "$SERVER_DIR":/src:ro "$NODE_IMAGE" bash -c '
set -uo pipefail
cp -r /src /tmp/server && cd /tmp/server && rm -rf node_modules
echo "Node $(node -v), npm $(npm -v)"
npm install --omit=dev --no-audit --no-fund 2>&1 | tail -3
echo "Installed:"; npm ls --depth=0 2>/dev/null | tail -n +2

export PORT=3000 NODE_ENV=test NEW_RELIC_ENABLED=false NEW_RELIC_NO_CONFIG_FILE=true NEW_RELIC_APP_NAME=smoke
node start.js >/tmp/server.log 2>&1 &
for i in $(seq 1 30); do curl -sf localhost:3000/health >/dev/null 2>&1 && break; sleep 1; done

failures=0
check() { # check NAME EXPECTED_STATUS URL [curl args...]
  local name="$1" want="$2" url="$3"; shift 3
  local got; got=$(curl -s -o /tmp/body -w "%{http_code}" "$@" "localhost:3000$url")
  if [ "$got" = "$want" ]; then echo "PASS  $name ($got)"; else echo "FAIL  $name: wanted $want, got $got"; head -c 200 /tmp/body; echo; failures=$((failures+1)); fi
}

echo; echo "Checks:"
check "health"                    200 /health
check "restaurant list"           200 /api/restaurant
check "menu by name"              200 /api/restaurant/by-name/bbq_tofu_paradise
check "menu, name with apostrophe" 200 /api/restaurant/by-name/tropical_jeeves_cafe
check "menu, unknown name"        404 /api/restaurant/by-name/no_such_place
check "new relic config"          200 /api/nr-config
check "place an order"            201 /api/order -H "Content-Type: application/json" \
  -d "{\"deliverTo\":{\"name\":\"Smoke\",\"phone\":\"(503) 555-0100\"},\"restaurant\":{\"id\":\"x\",\"name\":\"BBQ Tofu Paradise\"},\"items\":[{\"id\":\"1\",\"name\":\"Taco\",\"price\":5,\"qty\":2}],\"total\":10}"
check "simulated error is a 500"  500 /simulate/error/sync

echo; echo "Error response format:"
curl -s localhost:3000/simulate/error/sync; echo
grep -qi "uncaught\|unhandled\|TypeError\|Cannot find module" /tmp/server.log && { echo "FAIL  server log has errors:"; grep -i "uncaught\|unhandled\|TypeError\|Cannot find module" /tmp/server.log | head -5; failures=$((failures+1)); }

echo; [ "$failures" -eq 0 ] && echo "All checks passed." || { echo "$failures check(s) failed."; echo "--- server log ---"; tail -8 /tmp/server.log | cut -c1-300; exit 1; }
'
