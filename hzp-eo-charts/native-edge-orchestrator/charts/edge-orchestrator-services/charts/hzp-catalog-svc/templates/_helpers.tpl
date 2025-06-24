{{/*
Function to get full image names from a pipeline manifest, this must be the same as the one in parent chart
*/}}

{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
{{- end -}}

{{- define "init.config" -}}
storage:
- name: hzp-seaweedfs
  type: SEAWEEDFS
  supportedFormat: GENERIC
  filePath:
  url: {{ tpl .Values.global.s3.url . | quote }}
  isDefault: true
- name: hzp-container-registry
  type: CONTAINERREGISTRY
  supportedFormat: CONTAINER_IMAGE
  url: {{ tpl .Values.global.containerRegistry.url . | quote }}
registry:
- name: hzp-eo-registry
  description: default registry
  type: INTERNAL
  format: GENERIC
  supportedArtifactType: [GENERIC]
  remoteUrl:
  remoteUserName:
  remotePassword:
  enableProxy: false
  proxyUrl:
  proxyUserName:
  proxyPassword:
  storageName: hzp-seaweedfs
  isDefault: true
- name: hzp-blueprint-registry
  description: default blueprint registry
  type: INTERNAL
  format: BLUEPRINT
  supportedArtifactType: [GENERIC]
  remoteUrl:
  remoteUserName:
  remotePassword:
  enableProxy: false
  proxyUrl:
  proxyUserName:
  proxyPassword:
  storageName: hzp-seaweedfs
  isDefault: false
- name: hzp-update-bundles-registry
  description: default update bundles registry
  type: INTERNAL
  format: GENERIC
  supportedArtifactType: [GENERIC]
  remoteUrl:
  remoteUserName:
  remotePassword:
  enableProxy: false
  proxyUrl:
  proxyUserName:
  proxyPassword:
  storageName: hzp-seaweedfs
  isDefault: false
- name: hzp-eo-update-bundles-registry
  description: default EO update bundles registry
  type: INTERNAL
  format: GENERIC
  supportedArtifactType: [GENERIC]
  remoteUrl:
  remoteUserName:
  remotePassword:
  enableProxy: false
  proxyUrl:
  proxyUserName:
  proxyPassword:
  storageName: hzp-seaweedfs
  isDefault: false 
- name: hzp-discovery-utility-bundle 
  description: default discovery utilities bundles registry
  type: INTERNAL
  format: GENERIC
  supportedArtifactType: [GENERIC]
  remoteUrl:
  remoteUserName:
  remotePassword:
  enableProxy: false
  proxyUrl:
  proxyUserName:
  proxyPassword:
  storageName: hzp-seaweedfs
  isDefault: false 
- name: hzp-brownfield-exec-bundle 
  description: default brownfield executable registry
  type: INTERNAL
  format: GENERIC
  supportedArtifactType: [GENERIC]
  remoteUrl:
  remoteUserName:
  remotePassword:
  enableProxy: false
  proxyUrl:
  proxyUserName:
  proxyPassword:
  storageName: hzp-seaweedfs
  isDefault: false 
artifact: []
catalog:
- name: default-catalog
  description: default catalog
  isDefault: true
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

{{- define "plugins.bp.brand" -}}
{{- if .dsp -}}
"dsp"
{{- else -}}
{{ .brand | quote}}
{{- end -}}
{{- end -}}
