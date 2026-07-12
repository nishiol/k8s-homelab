#!/usr/bin/env bash
set -euo pipefail

KUBE_CONTEXT="${KUBE_CONTEXT:?set KUBE_CONTEXT explicitly}"
SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
FLUX_OPERATOR_VERSION="0.54.1"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
current_context="$(kubectl config current-context)"

if [[ "$current_context" != "$KUBE_CONTEXT" ]]; then
  echo "refusing to continue: current context is '$current_context', expected '$KUBE_CONTEXT'" >&2
  exit 1
fi

if [[ ! -s "$SOPS_AGE_KEY_FILE" ]]; then
  echo "age identity not found: $SOPS_AGE_KEY_FILE" >&2
  exit 1
fi

existing_releases="$(
  helm --kube-context "$KUBE_CONTEXT" list --all-namespaces --output json \
    | jq -r '.[] | select(.name != "traefik" and .name != "traefik-crd") | "\(.namespace)/\(.name)"'
)"
if [[ -n "$existing_releases" ]]; then
  echo "existing Helm releases detected" >&2
  printf '%s\n' "$existing_releases" >&2
  echo "bootstrap supports clean k3s clusters only" >&2
  exit 1
fi

flux check --pre
helm --kube-context "$KUBE_CONTEXT" upgrade --install flux-operator \
  oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --version "$FLUX_OPERATOR_VERSION" \
  --namespace flux-system \
  --create-namespace \
  --wait \
  --timeout 5m

kubectl --context "$KUBE_CONTEXT" -n flux-system create secret generic sops-age \
  --from-file=identity.agekey="$SOPS_AGE_KEY_FILE" \
  --dry-run=client -o yaml \
  | kubectl --context "$KUBE_CONTEXT" apply -f -

kubectl --context "$KUBE_CONTEXT" apply \
  -f "$repo_root/clusters/homelab/flux-instance.yaml"
kubectl --context "$KUBE_CONTEXT" -n flux-system wait fluxinstance/flux \
  --for=condition=Ready \
  --timeout=30m
flux reconcile source git flux-system
flux reconcile kustomization flux-system --with-source
