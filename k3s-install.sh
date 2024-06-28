# REPLACE <changeme> OCCURRENCES IN .yaml CONFIGS!!!
# RUN ON SERVER HOST

sudo mkdir -p /etc/rancher/k3s
sudo cp k3s/config.yaml /etc/rancher/k3s/config.yaml
curl -sfL https://get.k3s.io | sh -
sudo cp k3s/local-storage-config.yaml /var/lib/rancher/k3s/server/manifests/local-storage-config.yam
sudo cp k3s/traefik-config.yaml /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
