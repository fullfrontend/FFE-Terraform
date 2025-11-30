#!/usr/bin/env bash
set -euo pipefail

KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
mkdir -p "$(dirname "$KEY_FILE")"

if [[ -f "$KEY_FILE" ]]; then
  echo "Age key already exists at $KEY_FILE"
else
  age-keygen -o "$KEY_FILE"
  chmod 600 "$KEY_FILE"
  echo "Generated age key at $KEY_FILE"
fi

PUB_KEY=$(age-keygen -y "$KEY_FILE")
echo "Public key: $PUB_KEY"
echo "Export these env vars in your shell/CI:"
echo "  export SOPS_AGE_KEY_FILE=\"$KEY_FILE\""
echo "  export SOPS_AGE_RECIPIENTS=\"$PUB_KEY\""
