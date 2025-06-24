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

{{- define "isFQDN" -}}
{{- $value := . -}}
{{- $length := (len $value) }}
{{- if and (lt $length 254) (regexMatch "^([a-zA-Z0-9-]{1,63}\\.)+[a-zA-Z]{2,63}$" $value) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "GetMTLSHostList" -}}
{{- $fqdnHistory := (include "GetFqdnHistoryList" (dict "fqdn" $.fqdn "namespace" $.namespace)) }}
{{- $fqdnHistoryList := splitList "," ($fqdnHistory | trim) }}
{{- $resultList := list }}
{{- $defaultHost := index $.default 0 }}
  {{- range $index, $element := $fqdnHistoryList }}
    {{- $valueToAdd := $defaultHost }}
    {{- if eq (include "isFQDN" $element) "true" -}}
      {{- $valueToAdd = printf "%s%s" $.prefix $element }}
    {{- end }}
    {{- $resultList = append $resultList $valueToAdd }}
  {{- end }}
{{- $resultList | toYaml | nindent 0 }}
{{- end }}

{{- define "FetchFqdnHistoryFromSecret" }}
{{- $secretName := "fqdn-history-secret" }}
{{- $oldSecret := lookup "v1" "Secret" $.namespace $secretName }}
{{- $fqdnHistoryList := "" }}
  {{- if and ($oldSecret) ($oldSecret.data) }}
  {{- $fqdnHistoryList = ($oldSecret.data.history | b64dec) }}
  {{- end }}
{{- $fqdnHistoryList }}
{{- end }}

{{- define "GetFqdnHistoryList" -}}
{{- $historyList := (include "FetchFqdnHistoryFromSecret" (dict "namespace" $.namespace)) }}
{{- $historyListLen := len $historyList }}
{{- $historyList = splitList "," $historyList }}
{{- $resultList := list }}
{{- $fqdn := $.fqdn }}
{{- if le $historyListLen 0 }}
  {{- $resultList = append $resultList $fqdn }}
{{- else }}
  {{- $resultList = $historyList }}
  {{- $lastIndex := sub (len $historyList) 1 }}
  {{- $lastElem := index $historyList $lastIndex }}
  {{- if ne $fqdn $lastElem -}}
    {{- $resultList = append $resultList $fqdn }}
  {{- end }}
{{- end }}
{{- join "," $resultList }}
{{- end }}

{{/*
Return nodeSelector for pod (specified for microservice or global)
{{ include "pods.nodeSelector" ( list .Values.path.to.microservice.section $ ) }}
*/}}
{{- define "pods.nodeSelector" -}}
{{- $msRoot := index . 0 -}}
{{- $ := index . 1 -}}
{{- if hasKey $msRoot "nodeSelector" -}}
    {{- $msRoot.nodeSelector | toYaml | nindent 0  -}}
{{- else if and (hasKey $.Values "global") (hasKey $.Values.global "nodeSelector") -}}
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
{{- else if and (hasKey $.Values "global") (hasKey $.Values.global "tolerations") -}}
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
{{- if and ($.Values.global).affinity $msRoot.affinity -}}
  {{- merge $.Values.global.affinity $msRoot.affinity | toYaml | nindent 0 -}}
{{- else if and (not ($.Values.global).affinity) $msRoot.affinity -}}
  {{- $msRoot.affinity | toYaml | nindent 0 -}}
{{- else if and ($.Values.global).affinity (not $msRoot.affinity) -}}
  {{- $.Values.global.affinity | toYaml | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Generate the ingress host
*/}}
{{- define "ingress.host.default" -}}
    {{ if eq "dsp-portal" .Release.Namespace }}
        {{- printf "%s" .Values.ingress.host -}}
    {{- else -}}
        {{- printf "%s-%s.%s" (include "microservice.fullname" .) .Release.Namespace .Values.domain -}}
    {{- end -}}
{{- end -}}

{{- define "ingress.host.portal" -}}
    {{ if .Values.global.ingress.fqdn }}
        {{- printf "%s" .Values.global.ingress.fqdn -}}
    {{- else -}}
        {{ if eq "dsp-portal" .Release.Namespace }}
            {{- printf "%s" .Values.ingress.host -}}
        {{- else -}}
            {{- printf "%s.%s" .Release.Namespace .Values.domain -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
