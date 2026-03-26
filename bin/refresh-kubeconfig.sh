#!/usr/bin/env bash
set -euo pipefail

# Refresh repo-local kubeconfig from DigitalOcean using doctl.
# Usage:
#   bin/refresh-kubeconfig.sh [cluster-name] [kubeconfig-path]
# Examples:
#   bin/refresh-kubeconfig.sh
#   bin/refresh-kubeconfig.sh ffe-k8s
#   KUBECONFIG=./.kube/config bin/refresh-kubeconfig.sh ffe-k8s

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_KUBECONFIG="$REPO_ROOT/.kube/config"
KUBECONFIG_PATH="${2:-${KUBECONFIG:-$DEFAULT_KUBECONFIG}}"
CLUSTER_NAME_ARG="${1:-}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

infer_cluster_from_kubeconfig() {
  local kubeconfig_path="$1"
  local current_ctx cluster_name

  if [[ ! -f "$kubeconfig_path" ]]; then
    return 1
  fi

  current_ctx="$(kubectl --kubeconfig "$kubeconfig_path" config current-context 2>/dev/null || true)"
  if [[ -z "$current_ctx" ]]; then
    return 1
  fi

  cluster_name="$(kubectl --kubeconfig "$kubeconfig_path" config view -o jsonpath="{.contexts[?(@.name=='$current_ctx')].context.cluster}" 2>/dev/null || true)"
  if [[ -z "$cluster_name" ]]; then
    return 1
  fi

  if [[ "$cluster_name" =~ ^do-[^-]+-(.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  printf '%s\n' "$cluster_name"
}

infer_cluster_from_repo_defaults() {
  local tf_var_name default_name

  tf_var_name="${TF_VAR_doks_name:-}"
  if [[ -n "$tf_var_name" ]]; then
    printf '%s\n' "$tf_var_name"
    return 0
  fi

  default_name="$(awk '
    $0 ~ /variable "doks_name"/ { invar = 1; next }
    invar && $0 ~ /default[[:space:]]*=/ {
      if (match($0, /"[^"]+"/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
    invar && $0 ~ /^}/ { invar = 0 }
  ' "$REPO_ROOT/variables.tf")"

  if [[ -n "$default_name" ]]; then
    printf '%s\n' "$default_name"
    return 0
  fi

  return 1
}

infer_cluster_from_doctl() {
  local cluster_count

  cluster_count="$(doctl kubernetes cluster list --format Name --no-header 2>/dev/null | awk 'NF { count++ } END { print count + 0 }')"
  if [[ "$cluster_count" == "1" ]]; then
    doctl kubernetes cluster list --format Name --no-header | awk 'NF { print; exit }'
    return 0
  fi

  return 1
}

require_cmd doctl
require_cmd kubectl

if ! doctl account get >/dev/null 2>&1; then
  echo "doctl is not authenticated. Run: doctl auth init" >&2
  exit 1
fi

mkdir -p "$(dirname "$KUBECONFIG_PATH")"
touch "$KUBECONFIG_PATH"

CLUSTER_NAME="$CLUSTER_NAME_ARG"

if [[ -z "$CLUSTER_NAME" ]]; then
  CLUSTER_NAME="$(infer_cluster_from_kubeconfig "$KUBECONFIG_PATH" || true)"
fi

if [[ -z "$CLUSTER_NAME" ]]; then
  CLUSTER_NAME="$(infer_cluster_from_repo_defaults || true)"
fi

if [[ -z "$CLUSTER_NAME" ]]; then
  CLUSTER_NAME="$(infer_cluster_from_doctl || true)"
fi

if [[ -z "$CLUSTER_NAME" ]]; then
  echo "Unable to infer the DOKS cluster name." >&2
  echo "Pass it explicitly: bin/refresh-kubeconfig.sh <cluster-name>" >&2
  echo "Available clusters:" >&2
  doctl kubernetes cluster list >&2 || true
  exit 1
fi

echo "Refreshing kubeconfig from DigitalOcean"
echo "Cluster: $CLUSTER_NAME"
echo "Kubeconfig: $KUBECONFIG_PATH"

KUBECONFIG="$KUBECONFIG_PATH" doctl kubernetes cluster kubeconfig save --set-current-context "$CLUSTER_NAME"

echo "Done. Current context: $(kubectl --kubeconfig "$KUBECONFIG_PATH" config current-context)"
