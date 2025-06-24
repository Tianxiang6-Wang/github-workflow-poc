{{/*
Expand the name of the chart.
*/}}
{{- define "registry.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "eo-management-%s" $name | trunc 63 | trimSuffix "-" -}}
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

{{/*
Function to get full image names from a pipeline manifest, this must be the same as the one in each children chart
*/}}
{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
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
Return volumeMounts for the registry container
*/}}
{{- define "registry.volumeMounts" -}}
- name: "{{ template "registry.name" . }}-volume-config"
  mountPath: "/etc/distribution"

{{- if .Values.secrets.htpasswd }}
- name: auth
  mountPath: /auth
  readOnly: true
{{- end }}

{{- if eq .Values.storage "filesystem" }}
- name: "{{ template "registry.name" . }}-volume-data"
  mountPath: /var/lib/registry/
{{- end }}

{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}

{{- end -}}

{{/*
Return volumes for a pod
*/}}
{{- define "registry.volumes" -}}
- name: {{ template "registry.name" . }}-volume-config
  configMap:
    name: {{ template "registry.name" . }}-config

{{- if eq .Values.storage "filesystem" }}
- name: {{ template "registry.name" . }}-volume-data
  {{- if .Values.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ if .Values.persistence.existingClaim }}{{ .Values.persistence.existingClaim }}{{- else }}{{ template "registry.name" . }}-pvc{{- end }}
  {{- else }}
  emptyDir: {}
  {{- end -}}
{{- end }}

{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}

{{- end -}}

{{- define "registry.envs" -}}
- name: REGISTRY_HTTP_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ template "registry.name" . }}-secret
      key: haSharedSecret

{{- if .Values.secrets.htpasswd }}
- name: REGISTRY_AUTH
  value: "htpasswd"
- name: REGISTRY_AUTH_HTPASSWD_REALM
  value: "Registry Realm"
- name: REGISTRY_AUTH_HTPASSWD_PATH
  value: "/auth/htpasswd"
{{- end }}

{{- if .Values.tlsSecretName }}
- name: REGISTRY_HTTP_TLS_CERTIFICATE
  value: /etc/ssl/docker/tls.crt
- name: REGISTRY_HTTP_TLS_KEY
  value: /etc/ssl/docker/tls.key
{{- end -}}

{{- if eq .Values.storage "filesystem" }}
- name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
  value: "/var/lib/registry"
{{- else if eq .Values.storage "azure" }}
- name: REGISTRY_STORAGE_AZURE_ACCOUNTNAME
  valueFrom:
    secretKeyRef:
      name: {{ template "registry.name" . }}-secret
      key: azureAccountName
- name: REGISTRY_STORAGE_AZURE_ACCOUNTKEY
  valueFrom:
    secretKeyRef:
      name: {{ template "registry.name" . }}-secret
      key: azureAccountKey
- name: REGISTRY_STORAGE_AZURE_CONTAINER
  valueFrom:
    secretKeyRef:
      name: {{ template "registry.name" . }}-secret
      key: azureContainer
{{- else if eq .Values.storage "s3" }}
- name: REGISTRY_STORAGE_S3_REGION
  value: {{ required ".Values.s3.region is required" .Values.s3.region }}
- name: REGISTRY_STORAGE_S3_BUCKET
  value: {{ required ".Values.s3.bucket is required" .Values.s3.bucket }}
{{- if or (and .Values.secrets.s3.secretKey .Values.secrets.s3.accessKey) .Values.secrets.s3.secretRef }}
- name: REGISTRY_STORAGE_S3_ACCESSKEY
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.secrets.s3.secretRef }}{{ .Values.secrets.s3.secretRef }}{{ else }}{{ template "registry.name" . }}-secret{{ end }}
      key: s3AccessKey
- name: REGISTRY_STORAGE_S3_SECRETKEY
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.secrets.s3.secretRef }}{{ .Values.secrets.s3.secretRef }}{{ else }}{{ template "registry.name" . }}-secret{{ end }}
      key: s3SecretKey
{{- end -}}

{{- if .Values.s3.regionEndpoint }}
- name: REGISTRY_STORAGE_S3_REGIONENDPOINT
  value: {{ .Values.s3.regionEndpoint }}
{{- end -}}

{{- if .Values.s3.rootdirectory }}
- name: REGISTRY_STORAGE_S3_ROOTDIRECTORY
  value: {{ .Values.s3.rootdirectory | quote }}
{{- end -}}

{{- if .Values.s3.encrypt }}
- name: REGISTRY_STORAGE_S3_ENCRYPT
  value: {{ .Values.s3.encrypt | quote }}
{{- end -}}

{{- if .Values.s3.secure }}
- name: REGISTRY_STORAGE_S3_SECURE
  value: {{ .Values.s3.secure | quote }}
{{- end -}}

{{- else if eq .Values.storage "swift" }}
- name: REGISTRY_STORAGE_SWIFT_AUTHURL
  value: {{ required ".Values.swift.authurl is required" .Values.swift.authurl }}
- name: REGISTRY_STORAGE_SWIFT_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ template "registry.name" . }}-secret
      key: swiftUsername
- name: REGISTRY_STORAGE_SWIFT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "registry.name" . }}-secret
      key: swiftPassword
- name: REGISTRY_STORAGE_SWIFT_CONTAINER
  value: {{ required ".Values.swift.container is required" .Values.swift.container }}
{{- end -}}

{{- with .Values.extraEnvVars }}
{{ toYaml . }}
{{- end -}}

{{- end -}}
