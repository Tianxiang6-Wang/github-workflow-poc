{{/*
Function to get full image names from a pipeline manifest, this must be the same as the one in parent chart
*/}}

{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
{{- end -}}

{{- define "init.db" -}}
templatePolicy:
- type: DEFAULT
  criteria:
  - key: IS_OPENSKU
    value: "False"
  - key: PLATFORM
    value: Default
  artifactMetadata: 
  - key: NAME
    value: EdgeOS
  - key: VERSION
    value: 0.0.0.0
- type: DEFAULT
  criteria:
  - key: IS_OPENSKU
    value: "False"
  - key: PLATFORM
    value: Server
  artifactMetadata: 
  - key: NAME
    value: EdgeOS
  - key: VERSION
    value: 0.0.0.0
- type: DEFAULT
  criteria:
  - key: IS_OPENSKU
    value: "False"
  - key: PLATFORM
    value: Gateway
  artifactMetadata: 
  - key: NAME
    value: EdgeOS
  - key: VERSION
    value: 0.0.0.0
- type: DEFAULT
  criteria:
  - key: IS_OPENSKU
    value: "False"
  - key: PLATFORM
    value: Client
  artifactMetadata: 
  - key: NAME
    value: EdgeOS
  - key: VERSION
    value: 0.0.0.0

platformMapping:
- deviceType: PowerEdge R660
  platform: Server
- deviceType: PowerEdge R760
  platform: Server
- deviceType: PowerEdge R760xa
  platform: Server
- deviceType: PowerEdge XR4510c
  platform: Server
- deviceType: PowerEdge XR4520c
  platform: Server
- deviceType: OptiPlex XE4 series
  platform: Client
- deviceType: Edge Gateway 3200
  platform: Gateway
- deviceType: Edge Gateway 5200
  platform: Gateway
- deviceType: PowerEdge R660xs
  platform: Server
- deviceType: PowerEdge R760xs
  platform: Server
- deviceType: PowerEdge XR5610
  platform: Server
- deviceType: PowerEdge XR7620
  platform: Server
- deviceType: PowerEdge XR8610t
  platform: Server
- deviceType: PowerEdge XR8620t
  platform: Server
- deviceType: Precision 5860 Tower
  platform: Server
- deviceType: Precision 7960 Tower
  platform: Server
- deviceType: Precision 7960 Rack
  platform: Server
- deviceType: PowerEdge T160
  platform: Server
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

{{/* Return the proper imagePullSecrets */}}
{{- define "images.pullSecrets" -}}
{{- if (.Values.global).imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}
