#!/usr/bin/env bash
set -euo pipefail

# Usage: APP_ENV=dev ./scripts/tofu-secrets.sh plan/apply ...
# Decrypts SOPS-encrypted tfvars before invoking tofu, then cleans up.

APP_ENV="${APP_ENV:-dev}"
SECRETS_FILE="${SECRETS_FILE:-secrets.tfvars.enc}"
DECRYPTED_FILE="${DECRYPTED_FILE:-.secrets.auto.tfvars}"

cleanup() {
  [[ -f "$DECRYPTED_FILE" ]] && rm -f "$DECRYPTED_FILE"
}
trap cleanup EXIT INT TERM

if [[ -f "$SECRETS_FILE" ]]; then
  sops -d "$SECRETS_FILE" > "$DECRYPTED_FILE"
fi

TF_VAR_app_env="$APP_ENV" tofu "$@"
