{{/*
Expand the name of the chart.
*/}}
{{- define "fusion-services.name" -}}
{{- default "fusion" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fusion-services.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "fusion" .Values.nameOverride }}
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
{{- define "fusion-services.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fusion-services.labels" -}}
helm.sh/chart: {{ include "fusion-services.chart" . }}
{{ include "fusion-services.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fusion-services.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fusion-services.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fusion-services.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fusion-services.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Generate certificates for fusion-services
*/}}
{{- define "fusion-services.gen-certs" -}}
{{- $ca := genCA "fusion-services-ca" 3650 }}
{{- if and (.Values.certs.ca_cert) (.Values.certs.ca_key) }}
{{- $ca = buildCustomCert .Values.certs.ca_cert .Values.certs.ca_key }}
{{- end }}
{{- $externalCert := genSignedCert "nginx" nil (list "nginx" "fusion-entrypoint") 3650 $ca -}}
{{- if and (.Values.certs.external_cert) (.Values.certs.external_key) }}
{{- $externalCert = buildCustomCert .Values.certs.external_cert .Values.certs.external_key }}
{{- end }}
{{- $internalCert := genSignedCert "nginx" nil (list "nginx" "fusion-entrypoint") 3650 $ca -}}
{{- if and (.Values.certs.internal_cert) (.Values.certs.internal_key) }}
{{- $internalCert = buildCustomCert .Values.certs.internal_cert .Values.certs.internal_key }}
{{- end }}
{{- $rabbitmqCert := genSignedCert "rabbitmq" nil (list "rabbitmq") 3650 $ca -}}
{{- if and (.Values.certs.rabbitmq_cert) (.Values.certs.rabbitmq_key) }}
{{- $rabbitmqCert = buildCustomCert .Values.certs.rabbitmq_cert .Values.certs.rabbitmq_key }}
{{- end }}
cloudify_internal_ca_cert.pem: {{ $ca.Cert | b64enc }}
cloudify_internal_ca_key.pem: {{ $ca.Key | b64enc }}
cloudify_external_cert.pem: {{ $externalCert.Cert | b64enc }}
cloudify_external_key.pem: {{ $externalCert.Key | b64enc }}
cloudify_internal_cert.pem: {{ $internalCert.Cert | b64enc }}
cloudify_internal_key.pem: {{ $internalCert.Key | b64enc }}
rabbitmq-cert.pem: {{ $rabbitmqCert.Cert | b64enc }}
rabbitmq-key.pem: {{ $rabbitmqCert.Key | b64enc }}
{{- end -}}

{{/*
Generate list of curl commands to download resources.  Argument to this function
is a list of two elements:
  - base directory for downloads
  - map of destination file names to download urls
Output is a string like:
  curl -o /dir/f1 -L ftp://files.com/1 && curl -o /dir/f2 -L http://files.org/2
*/}}
{{- define "fusion-services.curl-download" -}}
{{- $destination := index . 0 -}}
{{- $curls := list -}}
{{- range $artifact, $url := (index . 1) -}}
{{- $cmd := printf "curl -o %s/%s -L %s" $destination $artifact $url -}}
{{- $curls = append $curls $cmd -}}
{{- end -}}
{{- printf (join " && " $curls ) -}}
{{- end -}}

{{/*
Return the proper image name (registry/repository:tag)
{{ include "fusion-services.image.name" (dict "svc" (index .Values.path.to.svc.components "component-name" ) "repo" .Values.global.repository }}
*/}}
{{- define "fusion-services.image.name" -}}
  {{- $repo := .svc.repository | default .repo -}}
  {{- $project := .svc.project | default "" -}}
  {{- $image := .svc.image -}}
  {{- $version := .svc.version | default "latest" -}}
  {{- $image := printf "%s%s%s:%s" $repo $project $image $version -}}
  {{- $image -}}
{{- end -}}

{{/*
Return nodeSelector for pod (specified for microservice or global)
{{ include "fusion-services.nodeSelector" ( list .Values.path.to.microservice.section $ ) }}
*/}}
{{- define "fusion-services.nodeSelector" -}}
{{- $msRoot := index . 0 -}}
{{- $ := index . 1 -}}
{{- $nodeSelector := $.Values.global.nodeSelector -}}
{{- if $msRoot.nodeSelector -}}
    {{- $nodeSelector = $msRoot.nodeSelector -}}
{{- end -}}
{{- $nodeSelector | toYaml| nindent 0 -}}
{{- end -}}

{{/*
Return tolerations for pod (specified for microservice or global)
{{ include "fusion-services.tolerations" ( list .Values.path.to.microservice.section $ ) }}
*/}}
{{- define "fusion-services.tolerations" -}}
{{- $msRoot := index . 0 -}}
{{- $ := index . 1 -}}
{{- $tolerations := $.Values.global.tolerations -}}
{{- if $msRoot.tolerations -}}
    {{- $tolerations = $msRoot.tolerations -}}
{{- end -}}
{{- $tolerations | toYaml| nindent 0 -}}
{{- end -}}

{{/*
Return affinity for pod (specified for microservice or global)
{{ include "fusion-services.affinity" ( list .Values.path.to.microservice.section $ ) }}
*/}}
{{- define "fusion-services.affinity" -}}
{{- $msRoot := index . 0 -}}
{{- $ := index . 1 -}}
{{- $affinity := $.Values.global.affinity -}}
{{- if $msRoot.affinity -}}
    {{- $affinity = $msRoot.affinity -}}
{{- end -}}
{{- $affinity | toYaml| nindent 0 -}}
{{- end -}}

{{/* Return the proper imagePullSecrets */}}
{{- define "fusion-services.images.pullSecrets" -}}
{{- if (.Values.global).imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Set the s3_server_url parameter: when using builtin seaweedfs, generate the url
*/}}
{{- define "fusion-services.s3_server_url" -}}
{{- if .Values.seaweedfs.enabled -}}
  {{- tpl "http://seaweedfs-s3.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.seaweedfs.s3.port}}" . -}}
{{- else -}}
  {{- tpl .Values.rest_service.config.manager.s3_server_url . -}}
{{- end -}}
{{- end -}}

{{/*
Return env vars block with S3 credentials
*/}}
{{- define "fusion-services.s3_env_vars" -}}
- name: AWS_ENDPOINT_URL_S3
  value: "{{ include "fusion-services.s3_server_url" . }}"
- name: S3_RESOURCES_BUCKET
  value: {{ .Values.rest_service.config.manager.s3_resources_bucket }}
{{- if .Values.seaweedfs.enabled }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: seaweedfs-s3-secret
      key: admin_access_key_id
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: seaweedfs-s3-secret
      key: admin_secret_access_key
{{- else }}
{{- if not .Values.rest_service.irsa_service_account }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.rest_service.s3_access.k8s_secret_name }}
      key: AWS_ACCESS_KEY_ID
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.rest_service.s3_access.k8s_secret_name }}
      key: AWS_SECRET_ACCESS_KEY
{{- if .Values.rest_service.s3_access.aws_session_token }}
- name: AWS_SESSION_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.rest_service.s3_access.k8s_secret_name }}
      key: AWS_SESSION_TOKEN
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Set the vault_server_url parameter: when using builtin vault, generate the url
*/}}
{{- define "fusion-services.vault_server_url" -}}
{{- if .Values.vault.enabled -}}
  {{- tpl "http://vault.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.vault.server.service.port }}" . -}}
{{- else -}}
  {{- tpl .Values.rest_service.config.manager.vault_url . -}}
{{- end -}}
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
  value: "{{ .Values.vault.bootstrap.kvMountPath }}"
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
Return env vars block with postgresql connection parameters.
{{ include "fusion-services.postgres_env_vars" ( dict "dbRoot" .Values.some.service.db "root" $ "envPrefix" "prefixString") }}
*/}}
{{- define "fusion-services.postgres_env_vars" -}}
- name: {{ .envPrefix }}POSTGRES_HOST
  value: {{ (.dbRoot).db.host | default (((.root).Values).db).host }}
- name: {{ .envPrefix }}POSTGRES_PORT
  value: {{ (.dbRoot).db.port | default (((.root).Values).db).port | default 5432 | quote }}
- name: {{ .envPrefix }}POSTGRES_DB
  value: {{ (.dbRoot).db.dbName | default (((.root).Values).db).dbName }}
- name: {{ .envPrefix }}POSTGRES_USER
  value: {{ (.dbRoot).db.user | default (((.root).Values).db).user }}
- name: {{ .envPrefix }}POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ ((.dbRoot).db.k8sSecret).name | default (((.root).Values).db).k8sSecret.name }}
      key: {{ ((.dbRoot).db.k8sSecret).key | default (((.root).Values).db).k8sSecret.key }}
{{- end -}}


{{/*
Return env vars block with the secret keys envvars for the restservice.
{{ include "fusion-services.restservice_keys" . }}
*/}}
{{- define "fusion-services.restservice_keys" -}}
- name: ENCRYPTION_KEY
  valueFrom:
    secretKeyRef:
      name: {{ template "fusion-services.name" . }}-manager-security
      key: encryptionKey
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ template "fusion-services.name" . }}-manager-security
      key: secretKey
- name: HASH_SALT
  valueFrom:
    secretKeyRef:
      name: {{ template "fusion-services.name" . }}-manager-security
      key: hashSalt
{{- end -}}


{{/*
Return env vars block with RabbitMQ connection parameters.

{{ include "fusion-services.rabbitmq_env_vars" ( dict "rabbitmqRoot" .Values.some.service.rabbitmq "root" $ ) }}
*/}}
{{- define "fusion-services.rabbitmq_env_vars" -}}
{{- if .root.Values.rabbitmq.enabled }}
- name: RABBITMQ_HOST
  value: "{{- .root.Values.rabbitmq.fullnameOverride }}"
- name: RABBITMQ_MANAGEMENT_PORT
  value: "15671"
- name: RABBITMQ_USER
  value: {{ (.rabbitmqRoot).rabbitmq.auth.username | default (((.root).Values).rabbitmq).auth.username }}
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: "{{- .root.Values.rabbitmq.fullnameOverride }}"
      key: rabbitmq-password
{{- else }}
- name: RABBITMQ_HOST
  value: "{{- .root.Values.externalRabbitmq.host }}"
- name: RABBITMQ_MANAGEMENT_PORT
  value: "{{- .root.Values.externalRabbitmq.managementPort }}"
- name: RABBITMQ_USER
  value: "{{- .root.Values.externalRabbitmq.username }}"
- name: RABBITMQ_PASSWORD
{{- if .root.Values.externalRabbitmq.existingSecret }}
  valueFrom:
    secretKeyRef:
      name: "{{ .root.Values.externalRabbitmq.existingSecret }}"
      key: "{{ .root.Values.externalRabbitmq.passwordKey }}"
{{- else }}
  value: "{{- .root.Values.externalRabbitmq.password }}"
{{- end }}
- name: RABBITMQ_IS_EXTERNAL
  value: "true"
{{- end -}}
{{- end -}}

{{/*
Env vars with EO details.

{{ include "fusion-services.eo_env_vars" . }}
*/}}
{{- define "fusion-services.eo_env_vars" -}}
{{- if .Values.global.eoName }}
- name: EO_NAME
  value: {{ .Values.global.eoName }}
{{- end }}
{{- if (.Values.global.ingress).fqdn }}
- name: EO_FQDN
  value: {{ .Values.global.ingress.fqdn }}
{{- end }}
{{- end -}}

{{/*
Configuration environment variables that allow fine-tuning of Prometheus metrics related to db,
broker and manager services. `FUSION_DB_METRICS`, `FUSION_BROKER_METRICS`, `FUSION_MANAGER_METRICS`
make it possible to edit metrics allocation to one of those three categories, they are used in
reporting cluster status (`ne cluster status`).  While `FUSION_BASE_SERVICES` and
`FUSION_OPTIONAL_SERVICES` define mandatory and optional Fusion Manager's services, used in
reporting manager's status (`ne status`).
*/}}
{{- define "fusion-services.metrics_env_vars" -}}
{{- if .Values.prometheus.enabled -}}
- name: FUSION_DB_METRICS
  value: "postgresql_healthy"
- name: FUSION_BROKER_METRICS
  value: "rabbitmq_healthy"
- name: FUSION_MANAGER_METRICS
  value: "{{ template "fusion-services.name" . }}-api-service, {{ template "fusion-services.name" . }}-composer-backend, {{ template "fusion-services.name" . }}-composer-frontend, {{ template "fusion-services.name" . }}-execution-scheduler, {{ template "fusion-services.name" . }}-mgmtworker, {{ template "fusion-services.name" . }}-nginx, prometheus-server, {{ template "fusion-services.name" . }}-rest-service, {{ template "fusion-services.name" . }}-stage-backend, {{ template "fusion-services.name" . }}-stage-frontend, {{ template "fusion-services.name" . }}-blueprint, {{ template "fusion-services.name" . }}-plugins, {{ template "fusion-services.name" . }}-secrets"
- name: FUSION_BASE_SERVICES
  value: "{{ template "fusion-services.name" . }}-nginx, {{ template "fusion-services.name" . }}-mgmtworker, {{ template "fusion-services.name" . }}-rest-service, {{ template "fusion-services.name" . }}-api-service, {{ template "fusion-services.name" . }}-execution-scheduler, {{ template "fusion-services.name" . }}-blueprint, {{ template "fusion-services.name" . }}-plugins, {{ template "fusion-services.name" . }}-secrets"
- name: FUSION_OPTIONAL_SERVICES
  value: "{{ template "fusion-services.name" . }}-stage-backend, {{ template "fusion-services.name" . }}-composer-backend, {{ template "fusion-services.name" . }}-fileserver"
{{- end -}}
{{- end -}}


{{/*
Return name logLevel configuration setting
*/}}
{{- define "fusion-loglevel-configmap.name" -}}
{{- $logLevel := .Values.global.logLevel | default .Values.logLevel | default (dict "configMap" (dict "name" "" "globalLogLevelKey" "" "initialGlobalLogLevel" "")) -}}
{{- $logLevel.configMap.name -}}
{{- end -}}


{{/*
Return globalLogLevelKey logLevel configuration setting
*/}}
{{- define "fusion-loglevel-configmap.globalLogLevelKey" -}}
{{- $logLevel := .Values.global.logLevel | default .Values.logLevel | default (dict "configMap" (dict "name" "" "globalLogLevelKey" "" "initialGlobalLogLevel" "")) -}}
{{- $logLevel.configMap.globalLogLevelKey -}}
{{- end -}}


{{/*
Return initialGlobalLogLevel logLevel configuration setting
*/}}
{{- define "fusion-loglevel-configmap.initialGlobalLogLevel" -}}
{{- $logLevel := .Values.global.logLevel | default .Values.logLevel | default (dict "configMap" (dict "name" "" "globalLogLevelKey" "" "initialGlobalLogLevel" "")) -}}
{{- $logLevel.configMap.initialGlobalLogLevel -}}
{{- end -}}

{{/*
Return merged lists of values
{{ include "fusion-services.merge" ( list .Values.path.to.values1 .Values.path.to.values2 ) }}
*/}}
{{- define "fusion-services.merge" -}}
{{- $values1 := index . 0 -}}
{{- $values2 := index . 1 -}}
{{- if and $values1 $values2 -}}
  {{- merge (deepCopy $values1) (deepCopy $values2) | toYaml | nindent 0 -}}
{{- else if and $values1 (not $values2) -}}
  {{- $values1 | toYaml | nindent 0 -}}
{{- else if and (not $values1) $values2 -}}
  {{- $values2 | toYaml | nindent 0 -}}
{{- end -}}
{{- end -}}

{{- define "plugins.bp.brand" -}}
{{- if .dsp -}}
"dsp"
{{- else -}}
{{ .brand | quote}}
{{- end -}}
{{- end -}}
