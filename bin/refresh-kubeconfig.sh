#!/usr/bin/env bash
set -euo pipefail

# Refresh kubeconfig for the current cluster using doctl.
# Defaults KUBECONFIG to ./.kube/config if not provided.

KUBECONFIG="${KUBECONFIG:-./.kube/config}"

if [[ ! -f "$KUBECONFIG" ]]; then
  echo "Kubeconfig not found at $KUBECONFIG" >&2
  exit 1
fi

current_ctx=$(kubectl --kubeconfig "$KUBECONFIG" config current-context 2>/dev/null || true)
if [[ -z "$current_ctx" ]]; then
  echo "No current-context set in $KUBECONFIG" >&2
  exit 1
fi

cluster_name=$(kubectl --kubeconfig "$KUBECONFIG" config view -o jsonpath="{.contexts[?(@.name=='$current_ctx')].context.cluster}")
if [[ -z "$cluster_name" ]]; then
  echo "Unable to resolve cluster name from context '$current_ctx' in $KUBECONFIG" >&2
  exit 1
fi

cluster_name_doctl="$cluster_name"
if [[ "$cluster_name" =~ ^do-[^-]+-(.+)$ ]]; then
  cluster_name_doctl="${BASH_REMATCH[1]}"
fi

echo "Refreshing kubeconfig for cluster: $cluster_name_doctl (context: $current_ctx, raw: $cluster_name)"
if ! KUBECONFIG="$KUBECONFIG" doctl kubernetes cluster kubeconfig save --set-current-context "$cluster_name_doctl"; then
  echo "Retrying with raw cluster name: $cluster_name" >&2
  KUBECONFIG="$KUBECONFIG" doctl kubernetes cluster kubeconfig save --set-current-context "$cluster_name"
fi
echo "Done. Current-context: $(kubectl --kubeconfig "$KUBECONFIG" config current-context)"
