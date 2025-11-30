#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <plaintext.tfvars> <output.tfvars.enc>" >&2
  exit 1
fi

PLAINTEXT="$1"
OUTPUT="$2"

if [[ ! -f "$PLAINTEXT" ]]; then
  echo "Input file not found: $PLAINTEXT" >&2
  exit 1
fi

if [[ -z "${SOPS_AGE_RECIPIENTS:-}" ]]; then
  echo "SOPS_AGE_RECIPIENTS is not set. Run bin/age-init.sh and export the vars." >&2
  exit 1
fi

sops -e "$PLAINTEXT" > "$OUTPUT"
echo "Encrypted -> $OUTPUT (keep $PLAINTEXT$([[ "$PLAINTEXT" =~ \.enc$ ]] && echo '' || echo ' out of git'))."
