#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/k8s-homelab-render.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

render_release() {
  release_file="$1"
  chart_name="$2"
  release_name="$(yq -r '.spec.releaseName' "$release_file")"
  namespace="$(yq -r '.spec.targetNamespace' "$release_file")"
  values_file="$tmp_dir/${namespace}-${release_name}-values.yaml"
  output_file="$tmp_dir/${namespace}-${release_name}.yaml"

  yq '.spec.values // {}' "$release_file" > "$values_file"
  helm template "$release_name" "$repo_root/charts/$chart_name" \
    --namespace "$namespace" \
    --values "$values_file" > "$output_file"
  kubeconform -strict -ignore-missing-schemas \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    -summary "$output_file"
}

render_release "$repo_root/infrastructure/homelab/clusterissuer.yaml" clusterissuer
render_release "$repo_root/infrastructure/homelab/traefik-extra.yaml" traefik-extra
render_release "$repo_root/infrastructure/homelab/host-certificate.yaml" host-certificate
render_release "$repo_root/apps/homelab/flaresolverr.yaml" flaresolverr
render_release "$repo_root/apps/homelab/gluetun.yaml" gluetun
render_release "$repo_root/apps/homelab/jackett.yaml" jackett
render_release "$repo_root/apps/homelab/starr.yaml" starr
render_release "$repo_root/apps/homelab/seerr.yaml" seerr
render_release "$repo_root/apps/homelab/recyclarr.yaml" recyclarr
render_release "$repo_root/apps/homelab/torrserver-earth.yaml" torrserver
render_release "$repo_root/apps/homelab/torrserver-moon.yaml" torrserver
render_release "$repo_root/apps/homelab/wg-easy.yaml" wg-easy
