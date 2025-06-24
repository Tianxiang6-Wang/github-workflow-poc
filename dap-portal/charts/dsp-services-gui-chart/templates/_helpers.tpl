{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "microservice.name" -}}
{{- $chartName := .Chart.Name -}}
{{- $serviceName := .Values.nameOverride -}}
{{- printf "%s" $serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "microservice.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate a version string for the app 
*/}}
{{- define "microservice.version" -}}
{{- printf "%s-%v" (now | date "2006-01-02") .Values.config.env.buildid -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "microservice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Selector Labels
{{- define "microservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "microservice.labels" -}}
{{ include "microservice.selectorLabels" . }}
app.kubernetes.io/namespace: {{ .Release.Namespace }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "microservice.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}


## Ingress helpers
{{- define "common.ingress.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19-0" .Capabilities.KubeVersion.Version) -}}
      {{- print "networking.k8s.io/v1" -}}
  {{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
    {{- print "networking.k8s.io/v1beta1" -}}
  {{- else -}}
    {{- print "extensions/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{/*
Return if ingress is stable.
*/}}
{{- define "common.ingress.isStable" -}}
  {{- eq (include "common.ingress.apiVersion" .) "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Return if ingress supports ingressClassName.
*/}}
{{- define "common.ingress.supportsIngressClassName" -}}
  {{- or (eq (include "common.ingress.isStable" .) "true") (and (eq (include "common.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) -}}
{{- end -}}

{{/*
Return if ingress supports pathType.
*/}}
{{- define "common.ingress.supportsPathType" -}}
  {{- or (eq (include "common.ingress.isStable" .) "true") (and (eq (include "common.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "common.rbac.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}


## Keda Get ApiVersion
{{- define "common.keda.apiVersion" -}}
  {{- if .Capabilities.APIVersions.Has "keda.k8s.io/v1alpha1" }}
    {{- print "keda.k8s.io/v1alpha1" -}}
  {{- else -}}
    {{- print "keda.sh/v1alpha1" -}}
  {{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "microservice.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "microservice.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Generate the CSP headers - default
*/}}
{{- define "microservice.cspHeaders.default" -}}
{{- range $key, $val := .Values.csp.directives }}
    {{- printf "%s %s; " $key $val -}}
{{- end }}
{{- end -}}


{{/*
Generate the CSP headers - safari
*/}}
{{- define "microservice.cspHeaders.safari" -}}
{{- range $key, $val := .Values.csp.directives }}
    {{- if ne $key "worker-src" -}}
        {{- printf "%s %s; " $key $val -}}
    {{- end -}}
{{- end }}
{{- end -}}

{{/*
Generate the ingress host
*/}}
{{- define "ingress.host.default" -}}
    {{ if eq "dsp-portal" .Release.Namespace }}
        {{- printf "%s.%s" (include "microservice.fullname" .) .Values.domain -}}
    {{- else -}}
        {{- printf "%s-%s.%s" (include "microservice.fullname" .) (include "microservice.namespace" .) .Values.domain -}}
    {{- end -}}
{{- end -}}


