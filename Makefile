SHELL := /bin/bash
KUBECONFORM := kubeconform -strict -ignore-missing-schemas \
	-schema-location default \
	-schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

.PHONY: check flux-build helm-lint render secret-scan sops-check sops-validate validate

check: helm-lint render flux-build sops-check sops-validate validate secret-scan

helm-lint:
	@for chart in charts/*; do \
		if rg -q '^existingSecret:' "$$chart/values.yaml"; then \
			helm lint "$$chart" --set existingSecret=test-credentials; \
		else \
			helm lint "$$chart"; \
		fi; \
	done

render:
	@./scripts/render-local-charts.sh

flux-build:
	@kustomize build clusters/homelab >/tmp/k8s-homelab-cluster.yaml
	@kustomize build infrastructure/homelab >/tmp/k8s-homelab-infrastructure.yaml
	@kustomize build apps/homelab >/tmp/k8s-homelab-apps.yaml

sops-check:
	@./scripts/check-sops.sh

sops-validate:
	@./scripts/validate-sops.sh

secret-scan:
	@gitleaks dir . --redact --no-banner

validate: flux-build
	@$(KUBECONFORM) -skip Secret -summary /tmp/k8s-homelab-cluster.yaml
	@$(KUBECONFORM) -skip Secret -summary /tmp/k8s-homelab-infrastructure.yaml
	@$(KUBECONFORM) -skip Secret -summary /tmp/k8s-homelab-apps.yaml
