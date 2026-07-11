#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

if [[ ! -s "$SOPS_AGE_KEY_FILE" ]]; then
  echo "age identity not found: $SOPS_AGE_KEY_FILE" >&2
  exit 1
fi

cd "$repo_root"
while IFS= read -r file; do
  sops --decrypt "$file" \
    | kubeconform -strict -ignore-missing-schemas -summary
done < <(rg --files apps infrastructure -g '*.sops.yaml' | sort)
