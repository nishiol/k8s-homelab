# k8s-homelab

Declarative configuration for a two-node k3s cluster. Flux Operator manages the
Flux controllers from a `FluxInstance`, Flux reconciles the `main` branch over
HTTPS, Kustomize assembles Kubernetes resources, HelmRelease manages Helm
charts, and SOPS with age encrypts every committed Secret.

## Layout

```text
apps/homelab/            Application HelmRelease and SOPS Secret manifests
bootstrap/flux/          Flux Operator installation and cluster bootstrap
bootstrap/k3s/           Pinned k3s server and agent installation
charts/                  Local Helm charts
clusters/homelab/        FluxInstance and cluster entry point
infrastructure/homelab/  Cluster services, chart sources and SOPS Secrets
scripts/                 Rendering and validation helpers
```

The operator owns the Flux controllers and root Git sync. Flux applies
`infrastructure/homelab` first and then `apps/homelab`. The k3s-provided
`traefik` and `traefik-crd` Helm releases remain managed by k3s.

## Requirements

Install the local tools on macOS:

```bash
brew install fluxcd/tap/flux sops age kubeconform yq kustomize gitleaks \
  kubectl helm jq ripgrep
```

The scripts also require `bash` and `curl`.

Validate the complete repository before pushing:

```bash
make check
```

This lints and renders local charts, builds all Kustomize trees, validates
Kubernetes schemas and SOPS files, and scans the working tree for plaintext
secrets.

## Secrets

`.sops.yaml` contains the public age recipient. The private identity must stay
outside Git and defaults to:

```text
~/.config/sops/age/keys.txt
```

Set the path before validating or editing encrypted files:

```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
sops apps/homelab/secrets/gluetun-credentials.sops.yaml
```

Back up the identity separately from the repository. A clone cannot decrypt or
restore the current Secrets without it. Check a backup with:

```bash
age-keygen -y /path/to/backup/keys.txt
```

Application charts only consume Kubernetes Secrets through `existingSecret`;
they never generate credentials. Flux decrypts the committed SOPS manifests
with the `flux-system/sops-age` Secret created by the bootstrap script.

PVC contents, Longhorn data, TLS certificates and ACME account keys are runtime
state and require separate backups.

## Install k3s

The bootstrap scripts pin k3s to `v1.36.2+k3s1`. Before installing, configure
DNS and install Longhorn host requirements such as `open-iscsi` and
`nfs-common`.

Install the server:

```bash
sudo K3S_TLS_SAN=nishiol.ru \
  K3S_NODE_NAME=beelink-s12-pro \
  ./bootstrap/k3s/install-server.sh
```

Read the agent token on the server:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Install the agent:

```bash
sudo K3S_URL=https://nishiol.ru:6443 \
  K3S_TOKEN='<node-token>' \
  K3S_NODE_NAME=raspberrypi4 \
  ./bootstrap/k3s/install-agent.sh
```

Copy `/etc/rancher/k3s/k3s.yaml` to the administration workstation, replace
the loopback API address and create an explicit kubectl context.

## Bootstrap Flux Operator

Push the desired state before bootstrapping because Flux reads GitHub rather
than the local working tree. Then run:

```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
KUBE_CONTEXT=homelab ./bootstrap/flux/bootstrap.sh
```

The script verifies the current kubectl context and age identity. It accepts
the k3s-owned Traefik releases but refuses a cluster containing other Helm
releases. It installs the pinned Flux Operator chart, creates the SOPS key
Secret, applies the `FluxInstance` and waits for the operator-managed Flux
controllers and Git sync to become ready. The Git-managed `HelmRelease` then
adopts the operator release and manages subsequent upgrades.

Monitor reconciliation:

```bash
kubectl --namespace flux-system get fluxinstance flux
flux check
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods -A
```

A new cluster receives empty application PVCs. Restore persistent data
separately. Starr also expects the static `media-raspberrypi4` PVC to exist.

## Operations

Reconcile Git and inspect status:

```bash
kubectl --namespace flux-system get fluxinstance flux
flux reconcile source git flux-system
flux get kustomizations -A
flux get helmreleases -A
```

Inspect or reconcile one release:

```bash
kubectl describe helmrelease starr --namespace starr
helm history starr --namespace starr
flux reconcile helmrelease starr --namespace starr --with-source
```

Edit a Secret with `sops`, run `make check`, commit the encrypted file and push.
For a local chart change, also increment `charts/<name>/Chart.yaml.version`.
Local charts use `reconcileStrategy: Revision`, so every Git revision may create
a new Helm revision even if the rendered manifests are unchanged.

All Flux Kustomizations use `prune: true`. Removing a HelmRelease uninstalls the
release, and removing a Namespace can delete its PVCs and Secrets. Review the
diff and take storage backups before committing resource removals.

To update k3s, change `K3S_VERSION` in both scripts under `bootstrap/k3s/`,
back up the cluster, update the server first, verify it, and then update the
agent.

To update Flux Operator, change its chart version in both
`bootstrap/flux/bootstrap.sh` and `infrastructure/homelab/flux-operator.yaml`.
The operator automatically applies compatible Flux patch releases selected by
the `2.9.x` range in `clusters/homelab/flux-instance.yaml`.
