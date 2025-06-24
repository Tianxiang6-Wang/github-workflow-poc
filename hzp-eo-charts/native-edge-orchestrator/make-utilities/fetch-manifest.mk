## Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

## Fetch manifest file from Artifactory
CHART_YAML                := ./native-edge-orchestrator/charts/edge-orchestrator-services/Chart.yaml
MANIFEST_PATH             ?= https://isgedge.artifactory.cec.lab.emc.com/artifactory/isgedge-generic-local/artifacts/hzp/main/manifests/dapo/manifest_latest.yaml

fetch-manifest:
	@echo "Will download manifest from ${MANIFEST_PATH}"
	@curl -s -k ${MANIFEST_PATH} | sed "s~isgedge.artifactory.cec.lab.emc.com/isgedge-docker-virtual~${IMAGE_REGISTRY}~g" | sed "s~amaas-eos-mw1.cec.lab.emc.com:5070~${IMAGE_REGISTRY}~g" | sed "s~hzp-external~artifactory~g" > manifest.yaml
	#@curl -s -k https://isgedge.artifactory.cec.lab.emc.com/artifactory/isgedge-generic-virtual/artifacts/hzp/main/manifests/eo/dev_manifest_eo_main-2.3.0.43.yaml | sed "s~isgedge.artifactory.cec.lab.emc.com/isgedge-docker-virtual~${IMAGE_REGISTRY}~g" | sed "s~amaas-eos-mw1.cec.lab.emc.com:5070~${IMAGE_REGISTRY}~g" | sed "s~hzp-external~artifactory~g" > manifest.yaml
	#@cp manifest.yaml manifest_local.yaml
	@echo "Downloaded manifest file from Artifactory as file: manifest.yaml"

update-app-version: 
ifneq ("$(wildcard $(CHART_YAML))","")
	$(eval APPVER = $(shell cat manifest.yaml | grep manifest_eo_version: |cut -d":" -f2 | tr -d '[:space:]'))
	$(info $(APPVER))
	$(shell sed -i 's/.*appVersion:.*/appVersion: "$(APPVER)"/' native-edge-orchestrator/Chart.yaml)
endif 
