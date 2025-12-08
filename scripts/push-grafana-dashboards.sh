#!/usr/bin/env bash

# Update (push) local dashboards to Grafana, matching by title.
# Prompts once to confirm overwrite of dashboards with the same title.
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

# Confirm overwrite (default: yes). Can be pre-set via OVERWRITE=true/false.
if [[ -z "${OVERWRITE:-}" ]]; then
  read -r -p "Overwrite dashboards with same title? [Y/n] " ans
  ans_lc="$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')"
  case "${ans_lc}" in
    y|yes) OVERWRITE="true" ;;
    n|no) OVERWRITE="false" ;;
    "") echo "Cancelled."; exit 0 ;;
    *) OVERWRITE="false" ;;
  esac
fi

# jq expects a JSON boolean, not a string.
if [[ "${OVERWRITE}" == "true" ]]; then
  OVERWRITE_BOOL="true"
else
  OVERWRITE_BOOL="false"
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
    payload="$(echo "$dash_json" | jq --argjson ow "$OVERWRITE_BOOL" '{dashboard: .dashboard, overwrite: $ow, folderId: 0}')"
  else
    payload="$(echo "$dash_json" | jq --argjson ow "$OVERWRITE_BOOL" '{dashboard: ., overwrite: $ow, folderId: 0}')"
  fi

  resp="$(api_post "/api/dashboards/db" --data-binary @<(echo "$payload"))"
  if [[ "$(echo "$resp" | jq -r '.status // empty')" == "success" || "$(echo "$resp" | jq -r '.imported' // empty)" == "true" ]]; then
    echo "Imported/updated: $title"
  else
    echo "Failed to import $title : $resp" >&2
  fi
done
