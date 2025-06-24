# Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

include make-utilities/common-individual/config.mk
include make-utilities/check-env.mk
include make-utilities/fetch-manifest.mk
include make-utilities/install-generic.mk
include make-utilities/delete-pvc.mk

# can use docker/nerdctl or add alias docker=nerdctl in your env
export CONTAINER_CLI=nerdctl
# added variables for ece-agent plugin

PLUGIN_TARGET_DIR := plugins
PLUGIN_COMMAND := go mod tidy && GOEXPERIMENT=boringcrypto go build -buildmode=plugin
PLUGIN_CLEAN := rm -f *.so

# import env file
env-file ?= .env
# Conditional include .env
-include $(env-file)

ifdef OS
    RM = del /Q /F
    MKDIRP = mkdir $(subst /,\,$1)
    AWK = gawk
else
    RM = rm -rf
    MKDIRP = mkdir -p $1
    AWK = awk
endif

define plugin_loop
	@([ -d $(PLUGIN_TARGET_DIR) ] || [  "$(ls -A $(PLUGIN_TARGET_DIR))" ]) || exit 0 && \
	cd $(PLUGIN_TARGET_DIR) && \
	for dir in */; do \
	if [ -d "$$dir" ]; then \
	echo "plugin: $$dir"; \
	cd $$dir && $1 && cd .. ; \
	fi \
	done
endef

.PHONY: all

all: clean build test container-build lint ## default target, clean -> build -> test -> container-build -> lint

## Build:
install-tool-dependencies: ## Install tool dependencies
    ## v2.12.3 has a bug which prevents it from using, see https://github.com/vektra/mockery/issues/471
	$(GOCMD) get -d github.com/vektra/mockery/v2@v2.12.2
	$(GOCMD) get -d github.com/99designs/gqlgen
build-plugins: ## build all the plugin components presnet in the plugins folder
	$(call plugin_loop, $(PLUGIN_COMMAND))

build: build-plugins ## Build your project and put the output binary in bin/
	-$(call MKDIRP, bin)
	$(GOCMD) build -o bin/$(BINARY_NAME) .

watch: ## Run the code with air package to have automatic reload of code changes
	air

clean: ## Remove build generated files
	$(RM) bin
	$(RM) tmp
	$(GOCMD) clean
	$(call plugin_loop, $(PLUGIN_CLEAN) )	

## Docs:
doc: ## Build Go docs for the project
	-$(RM) $(DOC_FOLDER)
	-$(call MKDIRP, $(DOC_FOLDER))
	$(DOCCMD) --site-name=$(DOC_SITE_NAME) --site-footer=$(DOC_SITE_FOOTER) --destination=$(DOC_FOLDER)

## Test:
test: unit-test bench-test test-coverage ## Run the unit tests, bench tests and test coverage

generate: ## Generate project code
	$(GOCMD) generate ./...

generate-protobuf: ## Generate protobuf code from protofile
	protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative server/api/grpc/proto/$(PROTOFILE).proto
unit-test: ## Run the unit tests of the project
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval EXPORT_OPTION=> ./$(EXPORT_FOLDER)/$@.log)
endif
	$(GOTEST) -v ./... $(EXPORT_OPTION)

bench-test: ## Run the bench tests of the project
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval EXPORT_OPTION=> ./$(EXPORT_FOLDER)/$@.log)
endif
	$(GOTEST) -bench=. ./... -v -benchmem -benchtime=$(BENCH_TIME) $(EXPORT_OPTION)

test-coverage: ## Run the tests of the project and export the coverage
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval COVER_PROFILE_PATH=./$(EXPORT_FOLDER)/profile.cov)
	$(eval EXPORT_UNIT_TEST_OPTION=> ./$(EXPORT_FOLDER)/unit-test.log)
	$(eval EXPORT_TEST_COVERAGE_OPTION=> ./$(EXPORT_FOLDER)/test-coverage.log)
else
	$(eval COVER_PROFILE_PATH=profile.cov)
endif
	$(GOTEST) -cover -covermode=count -coverprofile=$(COVER_PROFILE_PATH) ./... $(EXPORT_UNIT_TEST_OPTION)
	$(GOCMD) tool cover -func $(COVER_PROFILE_PATH) $(EXPORT_TEST_COVERAGE_OPTION)

## Lint:
lint: lint-go ## Run all lints, lint-go, lint-yaml and lint-dockerfile
# TODO: Make lint-yaml work in Jenkins
# TODO: Make lint-dockerfile work in Jenkins

lint-go: ## Use golintci-lint on your project
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval EXPORT_OPTION=> ./$(EXPORT_FOLDER)/$@.log 2>&1)
endif
	$(LINTCMD) run ./... -v --config=$(LINT_CONFIG_FILE) $(EXPORT_OPTION)

lint-yaml: ## Use yamllint for linting yaml files
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval EXPORT_OPTION=> ./$(EXPORT_FOLDER)/$@.log 2>&1)
endif
	$(CONTAINER_CLI) run --rm -v $(PWD):/data cytopia/yamllint:latest -f auto $(shell git ls-files *.yaml *.yml) $(EXPORT_OPTION)

lint-dockerfile: ## Use dockerlint for linting docker file
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval EXPORT_OPTION=> ./$(EXPORT_FOLDER)/$@.log 2>&1)
endif
	$(CONTAINER_CLI) run --rm -v $(PWD)/$(DOCKER_FILE):/Dockerfile:ro redcoolbeans/dockerlint $(EXPORT_OPTION)

## Run:
run: ## Run the component with go run main.go
	go run main.go

build-run: ## Run the go native binary
	-$(call MKDIRP, bin)
	$(GOCMD) build -o bin/$(BINARY_NAME) .
	./bin/$(BINARY_NAME)

run-container-it: ## Run the container interactively
	$(CONTAINER_CLI) run -it --rm --name="$(BINARY_NAME)" $(BINARY_NAME)

run-container: ## Run the go container in detached mode
	$(CONTAINER_CLI) run -d --env-file=$(env-file) --name="$(BINARY_NAME)" $(BINARY_NAME)

## Container:
container-build: ## Use the dockerfile to build the container
	$(CONTAINER_CLI) --namespace=k8s.io build --rm --tag dev.local/$(BINARY_NAME) .

## SBOM:
sbom-gomod: ## Use cyclonedx-gomod to generate sbom for go modules
	$(SBOMCMD) mod -json -output $(MOD_BOMFILE_NAME)

## Install Edge Orchestrator chart
install-eo: fetch-manifest update-app-version
	$(eval INCLUDE_MANIFEST="YES")
	$(eval INDIVIDUAL_REPO="YES")
	@eval CHART_DEP="native-edge-orchestrator"; \
	eval CHART_LOC=$(HZP_EO_HELM_CHART); \
	echo "$(INSTALL_GENERIC)";\
	eval $(INSTALL_GENERIC);

install-istio: prepare-istio install-inv-chart

prepare-%:
	$(eval INDIVIDUAL_REPO="YES")
	$(eval chart_to_deploy = $(subst prepare-,,$@))
	$(info $(chart_to_deploy))
	$(eval SUBCHART_HELM_CHART=$(HELM_REPO_LOCAL)$(chart_to_deploy))
	$(info Subchart is $(SUBCHART_HELM_CHART))
	$(shell rm -rf temp-chart)
	$(shell mkdir temp-chart; cd temp-chart; helm fetch $(SUBCHART_HELM_CHART) --untar)
	$(eval DEPENDENCIES_LIST = $(shell cat ./temp-chart/*/chart.dependencies) $(chart_to_deploy))
	$(info DEP_LIST : $(DEPENDENCIES_LIST))

install-subchart: prepare-$(SUBCHART) install-inv-chart

uninstall-%:
	helm uninstall $(subst uninstall-,,$@) -n $(NAMESPACE)

uninstall-eo: ## Uninstall-eo
	$(HELM) uninstall $(HZP_EO) -n $(NAMESPACE)

uninstall-subchart-only:
	$(HELM) uninstall $(SUBCHART) -n $(NAMESPACE)

uninstall-subchart: uninstall-subchart-only uninstall-dependencies

uninstall-dependencies:  ## Uninstall subchart dependencies
	@helm list -n $(NAMESPACE)|awk '{print $1}|while read line; do helm uninstall $$line -n $(NAMESPACE); done;

## Help:
help: ## Show this help.
	$(info )
	$(info Usage:)
	$(info $(EMPTY)  make <target>)
	$(info )
	$(info Targets)
	@$(AWK) 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-30s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)


## Locales:
generate-locales: ## Generate locale resource files
	$(GOCMD) generate ./locale/cmd/localize.go
