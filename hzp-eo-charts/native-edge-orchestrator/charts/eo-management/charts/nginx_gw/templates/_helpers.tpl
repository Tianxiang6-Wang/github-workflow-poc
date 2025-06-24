{{- define "DisplayFqdnOrDefaultValue" -}}
{{- $prefix := $.prefix }}
{{- $fqdn := $.fqdn }}
{{- $default := $.default }}
{{- if eq (include "isFQDN" $fqdn) "true" -}}
{{- $prefix -}}{{- $fqdn -}}
{{- else -}}
{{- $default -}}
{{- end -}}
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
