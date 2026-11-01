#!/usr/bin/env bash
# Uploads the Angular build's source maps to New Relic so browser stack traces show original TypeScript.
# Run after every build: chunk file names are hashed, and New Relic matches maps by exact JS URL.
# Usage: scripts/upload-sourcemaps.sh [site-url]   (default http://localhost)
set -euo pipefail

cd "$(dirname "$0")/.."
set -a; source .env; set +a

: "${NEW_RELIC_API_KEY:?Set NEW_RELIC_API_KEY (a User API key) in .env}"
: "${NEW_RELIC_BROWSER_APP_ID:?Set NEW_RELIC_BROWSER_APP_ID (the numeric appId of the browser app) in .env}"

site_url="${1:-http://localhost}"
site_url="${site_url%/}"
dist="dist/browser"

for map in "$dist"/*.js.map; do
  js_file="$(basename "${map%.map}")"
  echo "Uploading $js_file"
  npx --yes @newrelic/publish-sourcemap "$map" "$site_url/$js_file" \
    --applicationId "$NEW_RELIC_BROWSER_APP_ID" \
    --apiKey "$NEW_RELIC_API_KEY"
done
