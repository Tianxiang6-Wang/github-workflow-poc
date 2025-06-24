# Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.
EMPTY                           :=

# set to true to export selected make target's output
EXPORT_MAKEOUTPUT               := false
EXPORT_FOLDER                   := tmp

ifdef OS
    RM      = del /S /Q /F
    MKDIRP  = mkdir $(subst /,\,$1)
    AWK     = gawk
else
    RM      = rm -rf
    MKDIRP  = mkdir -p $1
    AWK     = awk
endif

.PHONY: npm-all

npm-all: clean install build test lint ## Default target, clean -> install -> build -> test -> lint

## Build:
build: ## Generate built files under /dist folder
	npm run build

install: ## Use npm install
	npm install --force

run: ## Run the service on non-standalone mode
	npm start

clean: ## Remove build generated files
	$(RM) dist
	$(RM) tmp
	$(RM) src\coverage\

## Test:
test: unit-test ## Run unit-test make target

unit-test: ## Use npm run test command
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval EXPORT_OPTION=> ./$(EXPORT_FOLDER)/$@.log 2>&1)
endif
	npm run test $(EXPORT_OPTION)

## Lint:
lint: lint-npm ## Run lint-npm make target

lint-npm: ## Use npm run lint for linting js,ts,tsx files
ifeq ($(EXPORT_MAKEOUTPUT), true)
	-$(call MKDIRP, $(EXPORT_FOLDER))
	$(eval EXPORT_OPTION=> ./$(EXPORT_FOLDER)/$@.log 2>&1)
endif
	npm run lint $(EXPORT_OPTION)

## Help:
help: ## Show this help
	$(info )
	$(info Usage:)
	$(info $(EMPTY)  make <target>)
	$(info )
	$(info Targets)
	@$(AWK) 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-30s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)

