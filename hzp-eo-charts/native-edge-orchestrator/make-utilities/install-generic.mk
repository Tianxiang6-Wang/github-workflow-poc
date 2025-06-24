## Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

include make-utilities/check-env.mk

ENV_FILE                 := ./.env
GET_ISTIO_POD_NAME       := $(KUBE_CTL) get po -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}'
GET_ISTIO_POD_STATUS     := $(KUBE_CTL) get po -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[*].status.phase}'|tr " " "\n"|sort -u
CHECK_ISTIO_READY        := curl -v -o 2>/dev/null -s -w "%{http_code}\n" localhost:15021/healthz/ready 2>/dev/null
JOB_TIMEOUT 			 ?= 10m
CHECK_VAULT_STATUS		 := $(KUBE_CTL) wait -n $(NAMESPACE) --for=condition=complete --timeout=$(JOB_TIMEOUT) job/vault-bootstrap 2>/dev/null
VAULT_POD_NAME			 := $(KUBE_CTL) get pods -n $(NAMESPACE) -o name | grep 'vault-bootstrap' | tail -1
GET_ISTIO_PORT_FW_PID    := lsof -t -i :15021 | awk '{print $1}'
SMOKE_TEST_PARAMS        :=
INCLUDE_MANIFEST="NO"
LOCAL_REPO="NO"
INDIVIDUAL_REPO="NO"
FUSION_CHART_DIR_PATH    := ./fusion-helm/fusion-services/
INIT_FUSION_DEPENDENCY   := helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm \
							&& helm repo add hashicorp https://helm.releases.hashicorp.com && pushd $(FUSION_CHART_DIR_PATH) && helm dependency build && popd
MANIFEST_EO_VERSION      :="$$(cat manifest.yaml | grep manifest_eo_version: |cut -d":" -f2 | tr -d '[:space:]')"

# TODO hardcoding default variables, to be removed after variables are passed from CI secrets
export VMS_ACCESS_TOKEN_ENDPT := VMS_ACCESS_TOKEN_ENDPT
export VMS_ACCESS_TOKEN_TYPE := VMS_ACCESS_TOKEN_TYPE
export VMS_ACCESS_TOKEN_USER := VMS_ACCESS_TOKEN_USER
export VMS_ACCESS_TOKEN_PASS := VMS_ACCESS_TOKEN_PASS
export VMS_XFER_VOUCHER_ENDPT := VMS_XFER_VOUCHER_ENDPT
export VMS_XFER_VOUCHER_TYPE := VMS_XFER_VOUCHER_TYPE
export VMS_XFER_VOUCHER_OAUTH := VMS_XFER_VOUCHER_OAUTH
export VMS_XFER_VOUCHER_APP_ID := VMS_XFER_VOUCHER_APP_ID
export VMS_XFER_VOUCHER_SECRET := VMS_XFER_VOUCHER_SECRET
export SRS_CLIENT_ID := SRS_CLIENT_ID
export SRS_CLIENT_SECRET := SRS_CLIENT_SECRET
export DL_CLIENT_ID := DL_CLIENT_ID
export DL_CLIENT_SECRET := DL_CLIENT_SECRET
export DELL_DIGITAL_TOKEN_URL := DELL_DIGITAL_TOKEN_URL
export MTLS_ENABLED := true
export AUTHV2_ENABLED := true
export ISTIO_SIDECAR_ENABLED := true

INSTALL_GENERIC=. $(ENV_FILE) && echo installing $$CHART_DEP && helm upgrade --install --wait $$CHART_DEP $$CHART_LOC --create-namespace -n $(NAMESPACE) --dependency-update --kube-context=$(CLUSTER_NAME) -f auth.yaml \
		$(if $(filter $(INCLUDE_MANIFEST),"YES"),-f manifest.yaml --set eo-management.delco-svc.svc.manifest_eo_version=$(MANIFEST_EO_VERSION)) \
		$(if $(filter $(EO_TEST_ENABLED),"true"),-f $(NEO_GLOBAL_SMOKETEST_YAML)) \
		$(if $(filter $(LOCAL_REPO),"YES"),--set $$MOD_TYPE.image.repository=dev.local/ --set $$MOD_TYPE.image.pullPolicy=\"Never\") \
		--set global.dockerSecret.dockerconfigjson=$$DOCKER_CONFIG_JSON --set global.ingress.fqdn=$$FQDN \
		--set global.postgresql.auth.postgresPassword=$$POSTGRES_PASSWORD \
		--set global.repository=$(IMAGE_REGISTRY)/ --set global.imageRegistry=$(IMAGE_REGISTRY) \
		--set fusion-services-helm.image.registry=$(IMAGE_REGISTRY) --set fusion-services-helm.nginx.image.registry=$(IMAGE_REGISTRY) \
		--set mist-ee.image.registry=$(IMAGE_REGISTRY) \
		--set global.postgresql.auth.keycloakDbPassword=$$KEYCLOAK_DB_PASSWORD \
		--set global.keycloak.auth.keycloakAdminPassword=$$KEYCLOAK_PASSWORD --set global.keycloak.auth.keycloakAuthClientPassword=$$KEYCLOAK_AUTH_CLIENT_PASSWORD \
		--set global.keycloak.auth.keycloakIAMClientPassword=$$KEYCLOAK_IAM_CLIENT_PASSWORD \
		--set global.pgadmin.auth.pgAdminPassword=$$PGADMIN_PASSWORD \
		--set global.fido.auth.apiPassword=$$FIDO_API_PASSWORD --set global.fido.auth.sslPassword=$$FIDO_SSL_PASSWORD \
		--set global.ssh.auth.sshPassword=$$SSH_PASSWORD \
		--set global.product.auth.srsClientId=$$SRS_CLIENT_ID --set global.product.auth.srsClientSecret=$$SRS_CLIENT_SECRET \
		--set global.product.auth.dlClientId=$$DL_CLIENT_ID --set global.product.auth.dlClientSecret=$$DL_CLIENT_SECRET \
		--set global.product.auth.ddTokenURL=$$DELL_DIGITAL_TOKEN_URL \
		--set global.eoTest.image=$$MSVC_SMOKE_IMAGE --set global.workflowEngine.auth.k3sConfigSecretValue=$$WORKFLOW_ENGINE_CONFIG \
		--set global.eceAgentTest.env.sshRemoteHost=$$SSH_REMOTE_HOST --set global.eceAgentTest.env.sshUserName=$$SSH_USER_NAME \
		--set global.eceAgentTest.env.sshPassword=$$SSH_PASSWORD --set global.eceAgentTest.env.serviceTag=$$SERVICE_TAG \
		--set global.iamAuthZEnabled=$$MTLS_ENABLED \
		--set global.iamProxy.sidecarEnabled=$$ISTIO_SIDECAR_ENABLED \
		--set global.iamV2AuthZEnabled=$$AUTHV2_ENABLED \
		--set global.isPipelineDeploy=true \
		--set global.microsegmentation.deploy=true \
		--set global.test.enabled=$$TEST_ENABLED \
		--set global.cookie_domain="" \
		--set global.ip_mode=true \
		--timeout 3600s $$SMOKE_TEST_PARAMS \
		$(if $(MIST_GIT_COMMIT_HASH), --set mist-ee.image.tag=$(MIST_GIT_COMMIT_HASH)) \
		--set mist-ee.image.createSecret.dockerconfigjson=$$DOCKER_CONFIG_JSON \
		--set mist-ee.spire.enabled=$(ENABLE_SPIRE) \
		--set mist-ee.http.host=$$FQDN \
		$(if $(POSTGRES_HOST), --set fusion-services-helm.db.host=$(POSTGRES_HOST),) \
		$(EO_EXTRA_ARGS) \
		$(MIST_EXTRA_ARGS) \
		$(FUSION_EXTRA_ARGS) \
		$(NEO_EXTRA_ARGS)

DEPENDENCIES_LIST="$$(cat native-edge-orchestrator/charts/$$CHART_NAME/chart.dependencies)\\n$$CHART_NAME:$$CHART_VERSION"

CHART_DOES_NOT_EXIST="$(HELM) list --deployed -n $(NAMESPACE) --filter '^$$CHART_DEP$$' --short"

# test smoke test on catalog svc
# Deprecating... will be removed in future, it will be replaced by `install` moving forward
install-inv-chart: check-env install-prereqs edge-keys-download
	$(eval INCLUDE_MANIFEST="YES")
	$(eval LOCAL_REPO="NO")
	@eval CHART_DEP="native-edge-orchestrator"; \
	eval CHART_LOC="./native-edge-orchestrator"; \
	if [ TEST_ENABLED="true" ]; then \
		export SMOKE_TEST_PARAMS="--set svc.image.name=$(MSVC_IMAGE) --set test.image.name=$(MSVC_SMOKE_IMAGE) --set test.enabled=$(TEST_ENABLED) -f native-edge-orchestrator/values-inv-smoketest-disable-all.yaml"; \
	fi; \
	if [ "$(CHART_NAME)" = "hzp-iam-policy-svc" ] || [ "$(CHART_NAME)" = "keycloak" ]; then \
		SMOKE_TEST_PARAMS="$$SMOKE_TEST_PARAMS -f native-edge-orchestrator/charts/eo-management/charts/$(CHART_NAME)/values-inv-smoketest.yaml"; \
	elif [ "$(CHART_NAME)" = "hzp-vault-bootstrap" ]; then \
		SMOKE_TEST_PARAMS="$$SMOKE_TEST_PARAMS -f native-edge-orchestrator/charts/eo-management/charts/secrets/values-inv-smoketest.yaml"; \
	else \
		SMOKE_TEST_PARAMS="$$SMOKE_TEST_PARAMS -f native-edge-orchestrator/charts/edge-orchestrator-services/charts/$(CHART_NAME)/values-inv-smoketest.yaml"; \
	fi;
	echo "$(INSTALL_GENERIC)";\
	eval $(INSTALL_GENERIC);

edge-keys-download:
	@. ./.env && export JFROG_TOKEN=`echo $$DOCKER_CONFIG_JSON|base64 --decode|awk 'split($$0,arr,","); {for(i=1;i<length(arr);i++) {print ":"arr[i]}}'|grep -i ":\"password\""|awk -F "\"" '{print $$4}'`
	if [ -z $$JFROG_TOKEN ]; then
	@. ./.env && export JFROG_TOKEN=`echo $$FKLN_DOCKER_CONFIG_JSON|base64 --decode|awk 'split($$0,arr,","); {for(i=1;i<length(arr);i++) {print ":"arr[i]}}'|grep -i ":\"password\""|awk -F "\"" '{print $$4}'`
	fi
	## FRU Keys Download
	@curl -s -k -H "X-JFrog-Art-Api:$$JFROG_TOKEN" https://isgedge.artifactory.cec.lab.emc.com/artifactory/isgedge-generic-virtual/misc/fru-private-key.crt -o native-edge-orchestrator/charts/eo-management/charts/secrets/files/fru-private-key.crt
	@curl -s -k -H "X-JFrog-Art-Api:$$JFROG_TOKEN" https://isgedge.artifactory.cec.lab.emc.com/artifactory/isgedge-generic-virtual/misc/fru-public-key.crt -o native-edge-orchestrator/charts/eo-management/charts/secrets/files/fru-public-key.crt
	## EO Keys Download
	@curl -s -k -H "X-JFrog-Art-Api:$$JFROG_TOKEN" https://isgedge.artifactory.cec.lab.emc.com/artifactory/isgedge-generic-virtual/sigsaly/hzp_dev.pub -o native-edge-orchestrator/charts/edge-orchestrator-services/charts/hzp-upgrade-svc/files/hzp_dev.pub
	@curl -s -k -H "X-JFrog-Art-Api:$$JFROG_TOKEN" https://isgedge.artifactory.cec.lab.emc.com/artifactory/isgedge-generic-virtual/sigsaly/hzp_prod.pub -o native-edge-orchestrator/charts/edge-orchestrator-services/charts/hzp-upgrade-svc/files/hzp_prod.pub


# setup helm repository of subcharts
helm-repo-setup:
	@echo "Checking is FUSION chart exist..."
	@if [ -d "$(FUSION_CHART_DIR_PATH)" ]; then \
        echo "FUSION chart exists..."; \
		echo "Switching to local chart"; \
		$(INIT_FUSION_DEPENDENCY); \
		sed -i '/  - name: fusion-services-helm/{n;s/version: .*/$(shell helm show chart $(FUSION_CHART_DIR_PATH) | grep -E '^version:' | awk '{print $2}')/;}' native-edge-orchestrator/Chart.yaml; \
		sed -i '/^\s*- name: fusion-services-helm$$/,/^\s*- name:/ { /repository: "[^"]*"/d }' native-edge-orchestrator/Chart.yaml; \
		cp -R "$(FUSION_CHART_DIR_PATH)" native-edge-orchestrator/charts/fusion-services-helm; \
    else \
		echo "FUSION chart does not exist..."; \
		if [ -z "$(FUSION_VERSION)" ]; then \
			echo "Getting fusion-services-helm chart version from manifest..."; \
			sed -i '/  - name: fusion-services-helm/{n;s/version: .*/version: $(shell cat manifest.yaml | grep -A 2 fusion_helmchart | grep version | sed "s/version: //" | sed -e 's/^[[:space:]]*//')/;}' native-edge-orchestrator/Chart.yaml; \
		else \
			echo "Setting fusion-services-helm chart version to $(FUSION_VERSION)..."; \
			sed -i '/  - name: fusion-services-helm/{n;s/version: .*/version: $(FUSION_VERSION)/;}' native-edge-orchestrator/Chart.yaml; \
		fi \
    fi

#### TODO: remove once all the targets below are removed from pipeline ####################################
install-mist:
	@echo -e "\n*****\nDeprecated: mist-ee is now a dependency of native-edge-orchestrator\n*****\n"

add-helm-repo:
	@echo -e "\n*****\nDeprecated: mist-ee is now a dependency of native-edge-orchestrator\n*****\n"

uninstall-mist:
	@echo -e "\n*****\nDeprecated: mist-ee is now a dependency of native-edge-orchestrator\n*****\n"

install-fusion:
	@echo -e "\n*****\nDeprecated: fusion-services-helm is now a dependency of native-edge-orchestrator\n*****\n"

add-fusion-helm-repo:
	@echo -e "\n*****\nDeprecated: fusion-services-helm is now a dependency of native-edge-orchestrator\n*****\n"

uninstall-fusion:
	@echo -e "\n*****\nDeprecated: fusion-services-helm is now a dependency of native-edge-orchestrator\n*****\n"
############################################################################################################
