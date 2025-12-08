#!/usr/bin/env bash

# Export Grafana dashboards matching the titles of local JSON files in grafana/dashboards,
# then anonymize them (remove UID/ID/slug/url/version metadata) before writing back.
# Requirements: curl, jq, python3 (for URL encoding).
#
# Env vars:
#   GRAFANA_URL      (default: http://localhost:3000)
#   GRAFANA_TOKEN    (Bearer token, preferred)
#   GRAFANA_USER/PASSWORD (basic auth fallback if no token)

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required (for URL encoding)" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASH_DIR="${ROOT}/grafana/dashboards"

# Optional env file at project root
ENV_FILE="${ROOT}/.env.local"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  set -a
  source "$ENV_FILE"
  set +a
fi

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_TOKEN="${GRAFANA_TOKEN:-}"
GRAFANA_USER="${GRAFANA_USER:-}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-}"

# Allow .env.local in scripts/ fallback
ALT_ENV_FILE="${ROOT}/scripts/.env.local"
if [[ -f "$ALT_ENV_FILE" ]]; then
  set -a
  source "$ALT_ENV_FILE"
  set +a
  GRAFANA_URL="${GRAFANA_URL:-${GRAFANA_URL:-}}"
fi

if [[ -n "$GRAFANA_TOKEN" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer ${GRAFANA_TOKEN}")
elif [[ -n "$GRAFANA_USER" && -n "$GRAFANA_PASSWORD" ]]; then
  AUTH_ARGS=(-u "${GRAFANA_USER}:${GRAFANA_PASSWORD}")
else
  echo "Set either GRAFANA_TOKEN or GRAFANA_USER/GRAFANA_PASSWORD" >&2
  exit 1
fi

urlencode() {
  python3 - "$1" <<'PY'
import sys, urllib.parse
if len(sys.argv) < 2:
    sys.exit(1)
print(urllib.parse.quote(sys.argv[1]))
PY
}

api_get() {
  local path="$1"
  curl -sS "${AUTH_ARGS[@]}" -H "Content-Type: application/json" "${GRAFANA_URL}${path}"
}

for file in "${DASH_DIR}"/*.json; do
  [[ -f "$file" ]] || continue
  title="$(jq -r '.title // .dashboard.title // empty' "$file")"
  if [[ -z "$title" ]]; then
    echo "Skipping $file (no title found)" >&2
    continue
  fi

  encoded_title="$(urlencode "$title")"
  search_json="$(api_get "/api/search?query=${encoded_title}")"
  uid="$(echo "$search_json" | jq -r --arg t "$title" 'map(select(.title == $t)) | first | .uid // empty')"

  if [[ -z "$uid" || "$uid" == "null" ]]; then
    echo "No dashboard found in Grafana for title: $title" >&2
    continue
  fi

  export_json="$(api_get "/api/dashboards/uid/${uid}")"
  if [[ -z "$export_json" ]]; then
    echo "Failed to export dashboard uid=$uid (title=$title)" >&2
    continue
  fi

  # Remove identifying metadata (uid/id/slug/url/version) to anonymize.
  echo "$export_json" | jq '
    del(.meta.uid, .meta.slug, .meta.url)
    | del(.dashboard.uid, .dashboard.id, .dashboard.version, .dashboard.panels[].datasource.uid)
  ' > "$file"

  echo "Exported and anonymized: $title -> $file"
done
