{{/* vim: set filetype=mustache: */}}

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
app.kubernetes.io/name: {{ include "microservice.fullname" . }}
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

{{/*
Generate the external dns host
*/}}
{{- define "externaldns.host" -}}
    {{- $result := "" -}}
    {{- if and (.Values.ingress.hosts) (not .Values.ingress.multipath.enabled) -}}
        {{- range .Values.ingress.hosts -}}
            {{- $host := .host | default (include "ingress.host.default" $) -}}
            {{- if $result -}}
                {{- $result = printf "%s,%s" $result $host -}}
            {{- else -}}
                {{- $result = $host -}}
            {{- end -}}
        {{- end -}}
    {{- else if and (.Values.ingress.multipath.hosts) (.Values.ingress.multipath.enabled) -}}
        {{- range .Values.ingress.multipath.hosts -}}
            {{- $host := .host | default (include "ingress.host.default" $) -}}
            {{- if $result -}}
                {{- $result = printf "%s,%s" $result $host -}}
            {{- else -}}
                {{- $result = $host -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- $result -}}
{{- end -}}


{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "keycloak.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "keycloak.labels" -}}
helm.sh/chart: {{ include "keycloak.chart" . }}
{{ include "keycloak.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | trunc 63 | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak.name" . }}
app.kubernetes.io/instance: eo-management
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "keycloak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "keycloak.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the service DNS name.
*/}}
{{- define "keycloak.serviceDnsName" -}}
{{ include "keycloak.fullname" . }}-headless.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain }}
{{- end }}

{{- define "keycloak.databasePasswordEnv" -}}
{{- if or .Values.database.password .Values.database.existingSecret -}}
- name: KC_DB_PASSWORD
  valueFrom:
    secretKeyRef:
    {{- if .Values.database.existingSecret }}
      name: {{ .Values.database.existingSecret | default (printf "%s-database" (include "keycloak.fullname" . ))}}
    {{- end }}
      key: keycloak-db-password
  {{- end }}
{{- end -}}

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
