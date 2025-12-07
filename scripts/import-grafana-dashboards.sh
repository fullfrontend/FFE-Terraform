#!/usr/bin/env bash

# Import (push) local dashboards to Grafana, matching by title.
# If the title already exists, it will be overwritten.
# Requirements: curl, jq, python3.
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
  echo "python3 is required" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASH_DIR="${ROOT}/grafana/dashboards"

# Optional env files
for env_file in "${ROOT}/.env.local" "${ROOT}/scripts/.env.local"; do
  if [[ -f "$env_file" ]]; then
    # shellcheck source=/dev/null
    set -a
    source "$env_file"
    set +a
  fi
done

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_TOKEN="${GRAFANA_TOKEN:-}"
GRAFANA_USER="${GRAFANA_USER:-}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-}"

if [[ -n "$GRAFANA_TOKEN" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer ${GRAFANA_TOKEN}")
elif [[ -n "$GRAFANA_USER" && -n "$GRAFANA_PASSWORD" ]]; then
  AUTH_ARGS=(-u "${GRAFANA_USER}:${GRAFANA_PASSWORD}")
else
  echo "Set either GRAFANA_TOKEN or GRAFANA_USER/GRAFANA_PASSWORD" >&2
  exit 1
fi

api_post() {
  local path="$1"
  shift
  curl -sS "${AUTH_ARGS[@]}" -H "Content-Type: application/json" -X POST "${GRAFANA_URL}${path}" "$@"
}

for file in "${DASH_DIR}"/*.json; do
  [[ -f "$file" ]] || continue

  # Take either a dashboard wrapper or a plain dashboard
  dash_json="$(cat "$file")"
  title="$(echo "$dash_json" | jq -r '.dashboard.title // .title // empty')"
  if [[ -z "$title" ]]; then
    echo "Skipping $file (no title found)" >&2
    continue
  fi

  # Normalize payload for /api/dashboards/db
  if echo "$dash_json" | jq -e '.dashboard' >/dev/null 2>&1; then
    payload="$(echo "$dash_json" | jq '{dashboard: .dashboard, overwrite: true, folderId: 0}')"
  else
    payload="$(echo "$dash_json" | jq '{dashboard: ., overwrite: true, folderId: 0}')"
  fi

  resp="$(api_post "/api/dashboards/db" --data-binary @<(echo "$payload"))"
  if [[ "$(echo "$resp" | jq -r '.status // empty')" == "success" || "$(echo "$resp" | jq -r '.imported' // empty)" == "true" ]]; then
    echo "Imported/updated: $title"
  else
    echo "Failed to import $title : $resp" >&2
  fi
done
