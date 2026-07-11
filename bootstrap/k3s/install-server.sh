#!/usr/bin/env bash
set -euo pipefail

K3S_VERSION="${K3S_VERSION:-v1.36.2+k3s1}"
K3S_NODE_NAME="${K3S_NODE_NAME:-beelink-s12-pro}"
K3S_TLS_SAN="${K3S_TLS_SAN:?set K3S_TLS_SAN to the API DNS name or IP}"
K3S_CPU_CLASS="${K3S_CPU_CLASS:-medium}"
K3S_GPU_CLASS="${K3S_GPU_CLASS:-intel}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
config_dir=/etc/rancher/k3s
config_file="$config_dir/config.yaml"

if [[ ${EUID} -ne 0 ]]; then
  echo "run this script as root" >&2
  exit 1
fi

install -d -m 0750 "$config_dir"
install -m 0640 "$repo_root/bootstrap/k3s/config.yaml" "$config_file"
{
  printf 'node-name: "%s"\n' "$K3S_NODE_NAME"
  printf 'tls-san:\n'
  IFS=',' read -r -a tls_sans <<< "$K3S_TLS_SAN"
  for san in "${tls_sans[@]}"; do
    printf '  - "%s"\n' "$san"
  done
  printf 'node-label:\n  - "cpu=%s"\n  - "gpu=%s"\n' "$K3S_CPU_CLASS" "$K3S_GPU_CLASS"
} >> "$config_file"

install -d -m 0750 /var/lib/k8s-homelab/certs/host-certificate

curl -sfL https://get.k3s.io \
  | INSTALL_K3S_VERSION="$K3S_VERSION" sh -

echo "k3s server $K3S_VERSION installed as $K3S_NODE_NAME"
