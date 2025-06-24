{{/*
Function to get full image names from a pipeline manifest, this must be the same as the one in parent chart
*/}}

{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
{{- end -}}

{{- define "logLevel.configMap.volume" }}
{{- if .Values.global.logLevel}}
{{- if and .Values.global.logLevel.enabled .Values.global.logLevel.configMap }}
- name: log-level-configmap-volume
  configMap:
    name: {{ .Values.global.logLevel.configMap.name }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "logLevel.configMap.mount" }}
{{- if .Values.global.logLevel}}
{{- if and .Values.global.logLevel.enabled .Values.global.logLevel.configMap }}
- name: log-level-configmap-volume
  mountPath: {{ .Values.global.logLevel.configMap.mountDir }}
  readOnly: true
{{- end -}}
{{- end -}}
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

{{- define "FetchFqdnHistoryFromCM" }}
{{- $cmName := "fusion-mgmtworker-envvars" }}
{{- $oldCm := lookup "v1" "ConfigMap" $.namespace "fusion-mgmtworker-envvars" }}
{{- $fqdnHistoryList := "" }}
  {{- if and ($oldCm) ($oldCm.data.EO_FQDN) }}
  {{- $fqdnHistoryList = ($oldCm.data.EO_FQDN) }}
  {{- end }}
{{- $fqdnHistoryList }}
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
{{- $cmFqdn := (include "FetchFqdnHistoryFromCM" (dict "namespace" $.namespace)) }}
{{- $secretList := (include "FetchFqdnHistoryFromSecret" (dict "namespace" $.namespace)) }}
{{- $resultList := list }}
{{- if gt (len $secretList) 0 }}
  {{- $resultList = $secretList }}
{{- end }}
{{- if ne $cmFqdn "" }}
  {{- $resultList = append $resultList $cmFqdn }}
{{- end }}
{{ concat $resultList ( list $.fqdn ) | uniq | join "," }}
{{- end }}

{{- define "isFQDN" -}}
{{- $value := . -}}
{{- $length := (len $value) }}
{{- if and (lt $length 254) (regexMatch "^([a-zA-Z0-9-]{1,63}\\.)+[a-zA-Z]{2,63}$" $value) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "GetMTLSHost" -}}
  {{- $fqdnHistory := (include "GetFqdnHistoryList" (dict "fqdn" $.fqdn "namespace" $.namespace)) }}
  {{- $fqdnHistoryList := splitList "," ($fqdnHistory | trim) }}
  {{- $lastIndex := sub (len $fqdnHistoryList) 1 }}
  {{- $lastFQDN := index $fqdnHistoryList $lastIndex | trim -}}

  {{- $customHost := printf "%s%s" $.prefix $lastFQDN }}
  {{- if (empty $lastFQDN) -}}
    {{- $customHost = printf "%s%s" $.prefix $.fqdn -}}
  {{- end -}}

  {{- $defaultHost := printf "%s"  (join "," $.default) }}
  {{- $lastHost := "" -}}
  {{- if eq (include "isFQDN" $lastFQDN) "true" -}}
    {{ $customHost }}
  {{- else -}}
    {{ $defaultHost }}
  {{- end -}}
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
