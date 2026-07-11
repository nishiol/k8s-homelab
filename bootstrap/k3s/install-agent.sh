#!/usr/bin/env bash
set -euo pipefail

K3S_VERSION="${K3S_VERSION:-v1.36.2+k3s1}"
K3S_URL="${K3S_URL:?set K3S_URL, for example https://server:6443}"
K3S_TOKEN="${K3S_TOKEN:?set K3S_TOKEN to the server node token}"
K3S_NODE_NAME="${K3S_NODE_NAME:-raspberrypi4}"
K3S_CPU_CLASS="${K3S_CPU_CLASS:-slow}"

if [[ ${EUID} -ne 0 ]]; then
  echo "run this script as root" >&2
  exit 1
fi

curl -sfL https://get.k3s.io \
  | K3S_URL="$K3S_URL" \
    K3S_TOKEN="$K3S_TOKEN" \
    INSTALL_K3S_VERSION="$K3S_VERSION" \
    INSTALL_K3S_EXEC="agent --node-name $K3S_NODE_NAME --node-label cpu=$K3S_CPU_CLASS" \
    sh -

echo "k3s agent $K3S_VERSION installed as $K3S_NODE_NAME"
