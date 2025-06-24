## Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

include make-utilities/config.mk
include make-utilities/check-env.mk
include make-utilities/install-generic.mk
include make-utilities/fetch-manifest.mk
include make-utilities/delete-pvc.mk
include make-utilities/client-secret.mk

NAME                    := native-edge-orchestrator
SUBDIRS                 := $(shell ls -d native-edge-orchestrator/charts/edge-orchestrator-services/charts/*/)
top_targets             ?= test watch package push
ENV_FILE                := ./.env
CHECK_ISTIO_UNINSTALL   := $(KUBE_CTL) get ns | grep $(ISTIO)
CHECK_NS_UNINSTALL      := $(KUBE_CTL) get ns | grep $(NAMESPACE)
READ_ENV_FILE           := `cat $(ENV_FILE)`
PACKAGE_DIR		:= ./packages
GLOBAL_YAML              := ./native-edge-orchestrator/charts/edge-orchestrator-services/values.yaml
THIRD_PARTY_YAML := ./thirdParty-manifest.yaml


# traverse subdirs
.ONESHELL:
ifneq ($(SUBDIRS),)
$(top_targets)::
	for dir in $(SUBDIRS); do \
		helm package $$dir -d $(PACKAGE_DIR); \
	done
endif
# set oneshell exit code if command fails
.SHELLFLAGS = -ec

## lint all charts
lint-charts:
	$(HELM) lint ./native-edge-orchestrator/charts/edge-orchestrator-services -f $(GLOBAL_YAML) --with-subcharts

help:
	@echo "lint-charts       	: Lint the helm charts"
	@echo "check-env         	: To check the existence of .env file and the content"	
	@echo "fetch-manifest    	: To fetch version or environment manifest from Artifactory"
	@echo "install           	: To install the edge orchestrator helm chart, will check and install all dependencies needed"
	@echo "uninstall         	: To uninstall the edge orchestrator helm chart"
	@echo "uninstall-neo      	: To uninstall the native edge orchestrator helm chart"
	@echo "delete-pvc        	: To delete all persistent volume claim"

## TODO: Handle namespace properly
## Install NEO chart
install: install-prereqs edge-keys-download
	$(eval INCLUDE_MANIFEST="YES")
	$(eval LOCAL_REPO="NO")
	@eval CHART_DEP="native-edge-orchestrator"; \
	eval CHART_LOC="./native-edge-orchestrator"; \
    if [ "$(EO_TEST_ENABLED)" = "true" ]; then \
        export SMOKE_TEST_PARAMS="--set global.microsegmentation.deploy=false --set global.mist.deploy=false --set global.fusionServices.deploy=false --set test.image.name=$(MSVC_SMOKE_IMAGE) --set smoke-test.test.enabled=$(EO_TEST_ENABLED) --set global.smokeTest.deploy=$(EO_TEST_ENABLED) --set global.smokeTest.runJob=true"; \
    fi;
	echo "$(INSTALL_GENERIC)";\
	eval $(INSTALL_GENERIC);

install-prereqs: fetch-manifest helm-repo-setup update-app-version

upgrade:
	$(HELM) upgrade -f $(GLOBAL_YAML) -n $(NAMESPACE) $(NAME) native-edge-orchestrator/charts/edge-orchestrator-services/charts/$(NAME)

## Delete jobs for upgrade
delete-jobs:
	$(KUBE_CTL) delete job -n $(NAMESPACE) --all

## Uninstall all charts
uninstall: uninstall-neo delete-pvc remove-ns

uninstall-inv-chart:
	@helm uninstall $$CHART_NAME -n $(NAMESPACE)

uninstall-all-force:
	@helm list|tail -n +2|awk '{print $$1}' | while read line; do helm uninstall $$line -n $(NAMESPACE); done

## Uninstall NEO chart
uninstall-neo:
	@echo "Deleting mist-ee jobs in the namespace"; \
	for i in `$(KUBE_CTL) get jobs -n $(NAMESPACE) --no-headers=true | awk '/mist/{print $$1}'`; do $(KUBE_CTL) delete -n $(NAMESPACE) jobs $$i; done; \
	@$(HELM) uninstall $(NAME) -n $(NAMESPACE);
	if [[ "$(DELETE_PVC)" == "YES" ]]; then \
		echo "Deleting mist related PVCs in the namespace"; \
		for i in `$(KUBE_CTL) get pvc -n $(NAMESPACE) --no-headers=true | awk '/mist/{print $$1}'`; do $(KUBE_CTL) delete -n $(NAMESPACE) pvc $$i; done; \
	fi; \
	while true; do \
		if [ -z "`$($(KUBE_CTL) get pod -n $(NAMESPACE) | grep $(MIST_CHARTNAME))`" ]; then \
			echo "Mist is uninstalled"; \
			break; \
		else \
			echo "Waiting for mist to be uninstalled..."; \
			sleep 20s; \
		fi; \
	done;

## Remove namespace
remove-ns:
ifneq ("$(NAMESPACE)","default")
	@$(KUBE_CTL) delete ns $(NAMESPACE) --wait=false;
	@$(KUBE_CTL) proxy & 
	@$(KUBE_CTL) get namespace $(NAMESPACE) -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" > temp.json 2>&1;
	@curl -k -s -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$(NAMESPACE)/finalize > /dev/null;rm temp.json; sleep 5;
	@ps -ef | grep -v auto | grep kubectl | awk '{ system("kill " $$2)}' > /dev/null 2>&1
	@while true; do \
		if [ -z "`$(CHECK_NS_UNINSTALL)`" ]; then \
			echo "Namespace $(NAMESPACE) is removed"; \
			break; \
		else \
			echo "Waiting for namespace $(NAMESPACE) to be removed..."; \
			sleep 10; \
		fi; \
	done;
endif

eula-update:
	@echo "This target has been deprecated"

.PHONY: lint-charts help install check-env uninstall uninstall-eo remove-ns delete-pvc microsegmentation

mockserver:
	@helm upgrade --install -f $(THIRD_PARTY_YAML) --set global.dockerSecretQA.dockerconfigjson=$(DOCKER_SECRET_QA) --wait --kube-context=$(CLUSTER_NAME) $(EXTRA_ARGS_QA) -n $(NAMESPACE) mockserver qa-services/mockserver

qa-service: install-dev-qa-dep
	@helm upgrade --install -f $(THIRD_PARTY_YAML) --set global.dockerSecretQA.dockerconfigjson=$(DOCKER_SECRET_QA) --wait --kube-context=$(CLUSTER_NAME) $(EXTRA_ARGS_QA) -n $(NAMESPACE) hzp-qa-svc qa-services/hzp-qa-svc
	@make mockserver || true

install-dev-qa-dep:
	@helm upgrade --install hzp-ece-agent-test qa-services/hzp-ece-agent-test/ -n $(NAMESPACE) --kube-context=$(CLUSTER_NAME) $(EXTRA_ARGS_QA)
	@sleep 2
	@helm upgrade --install hzp-ece-simulator qa-services/hzp-ece-simulator/ -n $(NAMESPACE) --kube-context=$(CLUSTER_NAME) $(EXTRA_ARGS_QA)
	@sleep 2
	@helm upgrade --install hzp-iam-proxy-test qa-services/hzp-iam-proxy-test/ -n $(NAMESPACE) --kube-context=$(CLUSTER_NAME) $(EXTRA_ARGS_QA)
	@sleep 2
	@helm upgrade --install nats-box qa-services/nats-box/ -n $(NAMESPACE) --kube-context=$(CLUSTER_NAME) $(EXTRA_ARGS_QA)
	@sleep 2
	@helm upgrade --install pgadmin qa-services/pgadmin/ -n $(NAMESPACE) --kube-context=$(CLUSTER_NAME) $(EXTRA_ARGS_QA)

# TODO: remove once all the targets below are removed from pipeline
microsegmentation:
	@echo -e "\n*****\nmicrosegmentation make target is here only to support build pipeline calls. It is no longer needed to run explicitly since it is moved into native-edge-orchestrator as a sub chart\n*****\n"
