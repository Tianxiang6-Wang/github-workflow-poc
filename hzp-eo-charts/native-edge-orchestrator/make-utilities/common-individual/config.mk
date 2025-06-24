# Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.
GOCMD=go
GOTEST=$(GOCMD) test
GOVET=$(GOCMD) vet
BENCH_TIME=1s   # Set the bench time for go bench tests, default 1s
LINTCMD=golangci-lint
LINT_CONFIG_FILE=.git/configs/golangci.yaml     # set the lint file correctly
EMPTY :=
DOCCMD=godoc-static
DOC_FOLDER=server/docs
SBOMCMD=cyclonedx-gomod
DOCKER_FILE=Dockerfile
PROTOFILE=plugin

# set to true to export selected make target's output
EXPORT_MAKEOUTPUT=false
EXPORT_FOLDER=tmp

# helm related
SHELL               := /bin/bash
HELM                := helm
NAMESPACE           := hzp
ENV_FILE                := ./.env
READ_ENV_FILE           := `cat $(ENV_FILE)`

DOCKER_CONFIG_JSON      := "DOCKER_CONFIG_JSON"

HZP_EO       := eo
HZP_EO_HELM_CHART := isgedge-helm-virtual/edge-orchestrator
HZP_EO_HELM_CHART_VERSION :=

POSTGRES_PVC        := data-postgres-0
HARBOR_PVC          := data-harbor-redis-0 data-harbor-trivy-0 database-data-harbor-database-0 harbor-chartmuseum harbor-jobservice harbor-registry
NATS_PVC            := datadir-nats-jetstream-0
LOGGING_PVC         := logsdir-hzp-logging-0
ARCHIVE_PVC         := archive-pvc-0
VAULT_PVC_PREFIX    := data-edgevault
