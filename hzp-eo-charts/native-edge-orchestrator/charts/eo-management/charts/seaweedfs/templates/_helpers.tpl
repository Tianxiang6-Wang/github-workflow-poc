{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to
this (by the DNS naming spec). If release name contains chart name it will
be used as a full name.
*/}}
{{- define "seaweedfs.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "seaweedfs.chart" -}}
{{- printf "%s-helm" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "seaweedfs.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "eo-management-%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Inject extra environment vars in the format key:value, if populated
*/}}
{{- define "seaweedfs.extraEnvironmentVars" -}}
{{- if .extraEnvironmentVars -}}
{{- range $key, $value := .extraEnvironmentVars }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Return the proper filer image */}}
{{- define "filer.image" -}}
{{- if .Values.filer.imageOverride -}}
{{- $imageOverride := .Values.filer.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.imageName | toString -}}
{{- $tag := .Chart.AppVersion | toString -}}
{{- printf "%s%s%s:%s" $registryName $repositoryName $name $tag -}}
{{- end -}}
{{- end -}}

{{/* Return the proper dbSchema image */}}
{{- define "filer.dbSchema.image" -}}
{{- if .Values.filer.dbSchema.imageOverride -}}
{{- $imageOverride := .Values.filer.dbSchema.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.global.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.global.repository | toString -}}
{{- $name := .Values.filer.dbSchema.imageName | toString -}}
{{- $tag := .Values.filer.dbSchema.imageTag | toString -}}
{{- printf "%s%s%s:%s" $registryName $repositoryName $name $tag -}}
{{- end -}}
{{- end -}}

{{/* Return the proper master image */}}
{{- define "master.image" -}}
{{- if .Values.master.imageOverride -}}
{{- $imageOverride := .Values.master.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.imageName | toString -}}
{{- $tag := .Chart.AppVersion | toString -}}
{{- printf "%s%s%s:%s" $registryName $repositoryName $name $tag -}}
{{- end -}}
{{- end -}}

{{/* Return the proper s3 image */}}
{{- define "s3.image" -}}
{{- if .Values.s3.imageOverride -}}
{{- $imageOverride := .Values.s3.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.imageName | toString -}}
{{- $tag := .Chart.AppVersion | toString -}}
{{- printf "%s%s%s:%s" $registryName $repositoryName $name $tag -}}
{{- end -}}
{{- end -}}

{{/* Return the proper volume image */}}
{{- define "volume.image" -}}
{{- if .Values.volume.imageOverride -}}
{{- $imageOverride := .Values.volume.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.imageName | toString -}}
{{- $tag := .Chart.AppVersion | toString -}}
{{- printf "%s%s%s:%s" $registryName $repositoryName $name $tag -}}
{{- end -}}
{{- end -}}

{{/* check if any Volume PVC exists */}}
{{- define "volume.pvc_exists" -}}
{{- if or (or (eq .Values.volume.data.type "persistentVolumeClaim") (and (eq .Values.volume.idx.type "persistentVolumeClaim") .Values.volume.dir_idx )) (eq .Values.volume.logs.type "persistentVolumeClaim") -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* check if any Filer PVC exists */}}
{{- define "filer.pvc_exists" -}}
{{- if or (eq .Values.filer.data.type "persistentVolumeClaim") (eq .Values.filer.logs.type "persistentVolumeClaim") -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* check if any Master PVC exists */}}
{{- define "master.pvc_exists" -}}
{{- if or (eq .Values.master.data.type "persistentVolumeClaim") (eq .Values.master.logs.type "persistentVolumeClaim") -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* check if any InitContainers exist for Volumes */}}
{{- define "volume.initContainers_exists" -}}
{{- if or (not (empty .Values.volume.idx )) (not (empty .Values.volume.initContainers )) -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/* Return the proper imagePullSecrets */}}
{{- define "seaweedfs.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
{{- if kindIs "string" .Values.global.imagePullSecrets }}
imagePullSecrets:
  - name: {{ .Values.global.imagePullSecrets }}
{{- else -}}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
{{/* DELL custom modification to fit existing eo-management imagePullSecrets format */}}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Renders a value that contains template perhaps with scope if the scope is present.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ ) }}
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ "scope" $app ) }}
*/}}
{{- define "common.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}

{{/*
If HA is enabled, return the number of replicas equal to the nodes in the cluster.
*/}}
{{- define "ha.replicas" -}}
{{- if .Values.global.s3.enableHA -}}
  {{- $items := (lookup "v1" "Node" "" "").items -}}
  {{- len $items -}}
{{- else -}}
  1
{{- end -}}
{{- end -}}


{{/*
Returns the replicationPlacment formatted as "00x".
Replication policy corresponds to (data center)(rack)(volume server)
The total number of copies will be 1 + sum(digits)
*/}}
{{- define "ha.replicationPlacement" -}}
{{- $replicas := include "ha.replicas" . | int -}}
{{- $adjustedReplicas := sub $replicas 1 -}}
{{- printf "%03d" $adjustedReplicas -}}
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
