{{/*
Function to get full image names from a pipeline manifest, this must be the same as the one in parent chart
*/}}

{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "fileserver.name" -}}
{{- $name := .Chart.Name -}}
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

{{/* Return the proper imagePullSecrets */}}
{{- define "images.pullSecrets" -}}
{{- if (.Values.global).imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "controller.envs" -}}

{{- end -}}

{{/*
Return volumeMounts for the filer font
*/}}
{{- define "controller.volumeMounts" -}}
- mountPath: /etc/nginx/nginx.conf
  name: "{{ template "fileserver.name" . }}-main-config"
  subPath: nginx.conf
- mountPath: /etc/nginx/templates
  name: "{{ template "fileserver.name" . }}-templates"
- mountPath: /etc/nginx/lua
  name: "{{ template "fileserver.name" . }}-lua-scripts"
- mountPath: /etc/nginx/tls-credentials
  name: "{{ template "fileserver.name" . }}-dummy-dir"
- mountPath: /etc/nginx/mtls-credentials
  name: "{{ template "fileserver.name" . }}-dummy-dir"
- mountPath: /data/nginx/cache
  name: "{{ template "fileserver.name" . }}-cache"
{{- end -}}

{{/*
Return volumes for a pod
*/}}
{{- define "controller.volumes" -}}
- name: "{{ template "fileserver.name" . }}-main-config"
  configMap:
    name: {{ template "fileserver.name" . }}-main-config
- name: "{{ template "fileserver.name" . }}-templates"
  configMap:
    name: {{ template "fileserver.name" . }}-templates
- name: "{{ template "fileserver.name" . }}-lua-scripts"
  configMap:
    name: {{ template "fileserver.name" . }}-lua-scripts
- name: "{{ template "fileserver.name" . }}-dummy-dir"
  emptyDir: {}
- name: "{{ template "fileserver.name" . }}-cache"
  emptyDir: {}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}

{{- end -}}

{{/*
Return merged dict of 2 values
{{ include "common.merge" ( list .Values.path.to.values1 .Values.path.to.values2 ) }}
*/}}
{{- define "common.merge" -}}
{{- $values1 := index . 0 -}}
{{- $values2 := index . 1 -}}
{{- if and $values1 $values2 -}}
  {{- mergeOverwrite (deepCopy $values1) (deepCopy $values2) | toYaml | trim -}}
{{- else if and $values1 (not $values2) -}}
  {{- $values1 | toYaml | trim -}}
{{- else if and (not $values1) $values2 -}}
  {{- $values2 | toYaml | trim -}}
{{- end -}}
{{- end -}}

{{/*
Return merged annotations (global common + svc common + resource specific)
{{ include "common.annotations" ( list $ .Values.path.to.specific.annotations ) }}
*/}}
{{- define "common.annotations" -}}
{{- $root := index . 0 -}}
{{- $specAnnotations := index . 1 -}}
{{- $commonAnnotations := (include "common.merge" ( list $root.Values.global.commonAnnotations $root.Values.commonAnnotations )) | fromYaml -}}
{{- include "common.merge" ( list $commonAnnotations $specAnnotations ) -}}
{{- end -}}

