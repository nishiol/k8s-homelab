# REPLACE <changeme> OCCURRENCES IN .yaml CONFIGS!!!
# RUN ON ANY HOST WITH KUBECTL ACCESS TO YOUR CLUSTER

helm repo add jetstack https://charts.jetstack.io
helm repo add longhorn https://charts.longhorn.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
helm upgrade --install clusterissuer charts/clusterissuer --namespace cert-manager -f values/clusterissuer-values.yaml
helm upgrade --install traefik-extra charts/traefik-extra --namespace traefik-extra --create-namespace -f values/traefik-extra-values.yaml
helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace -f values/longhorn-values.yaml