{{/*
Function to get full image names from a pipeline manifest
*/}}

{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
{{- end -}}

{{/*
If global.storageClass is available, set it as storageClassName
*/}}
{{- define "pvc.storage.class.name" -}}
{{- if .global -}}
    {{- if .global.storageClass -}}
        {{- printf "storageClassName: %s" .global.storageClass -}}
    {{- end -}}
{{- end -}}
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

{{- define "product.prouctIdBlock" }}
{{- if not .Values.global.dsp.enabled -}}
{{- $dict := dict "productType" .Values.productidblock.productType "productName" .Values.productidblock.productName "productModel" .Values.productidblock.productModel "productVersion" .Values.productidblock.productVersion -}}
{{- if and .Values.global .Values.global.product .Values.global.product.productModel -}}
{{- $_ := set $dict "productModel" .Values.global.product.productModel -}}
{{- end -}}
{{- if and .Values.global .Values.global.product .Values.global.product.productVersion -}}
{{- $_ := set $dict "productVersion" .Values.global.product.productVersion -}}
{{- end -}}
{{- toJson $dict -}}
{{- else -}}
{{- $dict := dict "productType" .Values.dapproductidblock.productType "productName" .Values.dapproductidblock.productName "productModel" .Values.dapproductidblock.productModel "productVersion" .Values.dapproductidblock.productVersion -}}
{{- if and .Values.global .Values.global.product .Values.global.product.productModel -}}
{{- $_ := set $dict "productModel" .Values.global.product.productModel -}}
{{- end -}}
{{- if and .Values.global .Values.global.product .Values.global.product.productVersion -}}
{{- $_ := set $dict "productVersion" .Values.global.product.productVersion -}}
{{- end -}}
{{- toJson $dict -}}
{{- end -}}
{{- end -}}

{{- define "product.srstransfertype" -}}
{{- if not .Values.global.dsp.enabled -}}
     {{- printf "%s" .Values.srstransfertype -}}
{{- else -}}
     {{- printf "%s" .Values.dapsrstransfertype -}}
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

{{/* Return the proper imagePullSecrets */}}
{{- define "images.pullSecrets" -}}
{{- if (.Values.global).imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}
