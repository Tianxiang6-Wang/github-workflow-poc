{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opensearch.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "eo-management" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* Get secret-env-vars name. Pass a list of two items, $ and the deployment/job name */}}
{{- define "get.secretEnvVars.name" }}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $secretName := "" }}
{{- if hasKey $root.Values.deployment $name }}
  {{- if get (get $root.Values.deployment $name) "secretEnvVars" }}
    {{- $secretName = $name }}
  {{- end }}
{{- end }}
{{- if and (not $secretName) $root.Values.deployment.defaults.secretEnvVars }}
  {{- $secretName = "defaults" }}
{{- end }}
{{- $secretName }}
{{- end }}

{{/* Get secret-env-vars for pod for use in envFrom. Pass a list of two items, $ and the deployment/job name */}}
{{- define "get.secretEnvVars.envFrom" }}
{{- $root := index . 0 }}
{{- $secretName := include "get.secretEnvVars.name" . }}
{{- if $secretName }}
- secretRef:
    name: {{ include "opensearch.fullname" $root }}-secret-env-vars-{{ $secretName }}
{{- end }}
{{- end }}

{{/* Get secret-env-vars for pod for use in envFrom, with envFrom header. Pass a list of two items, $ and the deployment/job name */}}
{{- define "get.secretEnvVars.envFromWithHeader" }}
{{- $root := index . 0 }}
{{- $secretName := include "get.secretEnvVars.name" . }}
{{- if $secretName }}
envFrom:
- secretRef:
    name: {{ include "opensearch.fullname" $root }}-secret-env-vars-{{ $secretName }}
{{- end }}
{{- end }}

{{/* Return the proper imagePullSecrets */}}
{{- define "images.pullSecrets" -}}
{{- if (.Values.global).imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return nodeSelector for pod (specified for microservice or global)
{{ include "pods.nodeSelector" ( list .Values.path.to.microservice.section $ ) }}
*/}}
{{- define "pods.nodeSelector" -}}
{{- $msRoot := index . 0 -}}
{{- $ := index . 1 -}}
{{- if hasKey $msRoot "nodeSelector" -}}
    {{- $msRoot.nodeSelector | toYaml | nindent 0  -}}
{{- else if hasKey $.Values.global "nodeSelector" -}}
    {{- $.Values.global.nodeSelector | toYaml | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Return tolerations for pod (specified for microservice or global)
{{ include "pods.tolerations" ( list .Values.path.to.microservice.section $ ) }}
*/}}
{{- define "pods.tolerations" -}}
{{- $msRoot := index . 0 -}}
{{- $ := index . 1 -}}
{{- if hasKey $msRoot "tolerations" -}}
    {{- $msRoot.tolerations | toYaml | nindent 0 -}}
{{- else if hasKey $.Values.global "tolerations" -}}
    {{- $.Values.global.tolerations | toYaml | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Return affinity for pod (merged global and specified for microservice)
{{ include "pods.affinity" ( list .Values.path.to.microservice.section $ ) }}
*/}}
{{- define "pods.affinity" -}}
{{- $msRoot := index . 0 -}}
{{- $ := index . 1 -}}
{{- if and $.Values.global.affinity $msRoot.affinity -}}
  {{- merge $.Values.global.affinity $msRoot.affinity | toYaml | nindent 0 -}}
{{- else if and (not $.Values.global.affinity) $msRoot.affinity -}}
  {{- $msRoot.affinity | toYaml | nindent 0 -}}
{{- else if and $.Values.global.affinity (not $msRoot.affinity) -}}
  {{- $.Values.global.affinity | toYaml | nindent 0 -}}
{{- end -}}
{{- end -}}
