{{/*
Function to get full image names from a pipeline manifest, this must be the same as the one in parent chart
*/}}

{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
{{- end -}}

{{/*
Function to get postgres user. Default to postgres if .Values.global.postgresql.remote.user is not defined
*/}}

{{- define "getPostgresUser" -}}
{{- if and (eq .Values.global.postgresql.deploy false) (not (empty .Values.global.postgresql.remote.user)) -}}
{{- .Values.global.postgresql.remote.user }}
{{- else -}}
{{- "postgres" }}
{{- end -}}
{{- end -}}

{{/*
Function to get postgres host. Default to postgres if .Values.global.postgresql.remote.host is not defined
*/}}

{{- define "getPostgresHost" -}}
{{- if and (eq .Values.global.postgresql.deploy false) (not (empty .Values.global.postgresql.remote.host)) -}}
{{- .Values.global.postgresql.remote.host }}
{{- else -}}
{{- "postgres" }}
{{- end -}}
{{- end -}}

{{/*
Function to get postgres port. Default to 5432 if .Values.global.postgresql.remote.port is not defined
*/}}

{{- define "getPostgresPort" -}}
{{- if and (eq .Values.global.postgresql.deploy false) (not (empty .Values.global.postgresql.remote.port)) -}}
{{- .Values.global.postgresql.remote.port }}
{{- else -}}
{{- "5432" }}
{{- end -}}
{{- end -}}


{{/*
Function to get postgres url.
*/}}

{{- define "getPostgresUrl" -}}
{{- printf "jdbc:postgresql://%s:%s/" (include "getPostgresHost" .) (include "getPostgresPort" .) -}}
{{- end -}}

{{/*
Function to get postgres password. Use .Values.global.postgresql.auth.postgresPassword if not empty,
otherwise take secretRef from .Values.global.postgresql.auth.secretName
*/}}

{{- define "getPostgresPassword" -}}
{{- if and (eq .Values.global.postgresql.deploy false) (not (empty .Values.global.postgresql.remote.password)) -}}
value: {{ .Values.global.postgresql.remote.password }}
{{- else -}}
valueFrom:
  secretKeyRef:
    name: {{ .Values.global.postgresql.auth.secretName }}
    key: {{ .Values.global.postgresql.auth.hzpDbUserName }}-password
{{- end -}}
{{- end -}}

{{/* START Overriding seaweedfs helper function */}}
{{- define "filer.image" -}}
  {{- include "manifest.image.name" (dict "data" (index .Values.components "seaweedfs") "repo" .Values.global.repository) }}
{{- end -}}

{{- define "filer.dbSchema.image" -}}
  {{- include "manifest.image.name" (dict "data" (index .Values.components "seaweedfs") "repo" .Values.global.repository) }}
{{- end -}}

{{- define "master.image" -}}
  {{- include "manifest.image.name" (dict "data" (index .Values.components "seaweedfs") "repo" .Values.global.repository) }}
{{- end -}}

{{- define "s3.image" -}}
  {{- include "manifest.image.name" (dict "data" (index .Values.components "seaweedfs") "repo" .Values.global.repository) }}
{{- end -}}

{{- define "volume.image" -}}
  {{- include "manifest.image.name" (dict "data" (index .Values.components "seaweedfs") "repo" .Values.global.repository) }}
{{- end -}}

{{- define "seaweedfs.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
  {{- if kindIs "string" .Values.global.imagePullSecrets }}
  imagePullSecrets:
  - name: {{ .Values.global.imagePullSecrets }}
  {{- else -}}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
- name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
{{/* END Overriding seaweedfs helper function */}}

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
