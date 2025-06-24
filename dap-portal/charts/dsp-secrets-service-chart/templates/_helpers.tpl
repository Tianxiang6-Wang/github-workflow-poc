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
Return env vars block with Vault connection parameters
*/}}
{{- define "fusion-services.vault_env_vars" -}}
{{/* TODO: replace any reference to Values.rest_service.* with Values.secrets.* */}}
{{- if eq ( tpl .Values.rest_service.config.manager.default_secrets_backend . ) "vault" }}
- name: FUSION_VAULT_URL
  value: "{{ include "fusion-services.vault_server_url" . }}"
- name: FUSION_VAULT_PATH
  value: "{{ .Values.vault.kvMountPath }}"
- name: FUSION_VAULT_APPROLE_PATH
  value: "{{ .Values.vault.appRolePath }}"
{{/* TODO: remove ROLE_ID and SECRET_ID env vars after completely moved to secret-svc */}}
- name: FUSION_VAULT_ROLE_ID
  valueFrom:
    secretKeyRef:
      name: "{{ .Values.vault.componentName }}-vault-secret"
      key: role-id
- name: FUSION_VAULT_SECRET_ID
  valueFrom:
    secretKeyRef:
      name: "{{ .Values.vault.componentName }}-vault-secret"
      key: secret-id
{{- end -}}
{{- end -}}

{{/*
Set the vault_server_url parameter: when using builtin vault, generate the url
*/}}
{{- define "fusion-services.vault_server_url" -}}
  {{- tpl "http://{{ .Values.vault.host }}:{{ .Values.vault.port }}" . -}}
{{- end -}}



{{/*
Return env vars block with postgresql connection parameters.
{{- include "fusion-services.postgres_env_vars" (dict "dbRoot" .Values.secrets "root" $) | nindent 12 }}
*/}}
{{- define "fusion-services.postgres_env_vars" -}}
{{- if .root.Values.global.postgres.internal -}}
- name: {{ .envPrefix }}POSTGRES_HOST
  value: {{ (.dbRoot).host | default (((.root).Values).db).host }}
{{- else }}
- name: {{ .envPrefix }}POSTGRES_HOST
  value: {{ .root.Values.global.postgres.host }}
{{- end }}
- name: {{ .envPrefix }}POSTGRES_PORT
  value: {{ (.dbRoot).port | default (((.root).Values).db).port | default 5432 | quote }}
- name: {{ .envPrefix }}POSTGRES_DB
  value: {{ (.dbRoot).dbName | default (((.root).Values).db).dbName }}
- name: {{ .envPrefix }}POSTGRES_USER
  value: {{ ((.root).Values).dbinit.postgres.dbName | default "default" }}
- name: {{ .envPrefix }}POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ ((.dbRoot).k8sSecret).name | default (((.root).Values).db).k8sSecret.name }}
      key: {{ ((.dbRoot).k8sSecret).key | default (((.root).Values).db).k8sSecret.key }}
{{- end -}}

{{/*
Return database host address.
{{ include "fusion-services.postgres_host" . }}
*/}}
{{- define "fusion-services.postgres_host" -}}
{{- if .Values.global.postgres.internal -}}
{{- printf "%s" .Values.db.host  }}
{{- else }}
{{- printf "%s" .Values.global.postgres.host | default .Values.db.host }}
{{- end }}
{{- end -}}

{{/*
Return env vars block with the secret keys envvars for the restservice.
{{ include "fusion-services.restservice_keys" . }}
*/}}
{{- define "fusion-services.restservice_keys" -}}
- name: ENCRYPTION_KEY
  valueFrom:
    secretKeyRef:
      name: {{include "microservice.fullname" .}}-manager-security
      key: encryptionKey
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{include "microservice.fullname" .}}-manager-security
      key: secretKey
- name: HASH_SALT
  valueFrom:
    secretKeyRef:
      name: {{include "microservice.fullname" .}}-manager-security
      key: hashSalt
{{- end -}}
