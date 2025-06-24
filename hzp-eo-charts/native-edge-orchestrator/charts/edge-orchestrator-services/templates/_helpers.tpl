{{/*
Function to get full image names from a pipeline manifest, this must be the same as the one in each children chart
*/}}

{{- define "manifest.image.name" -}}
{{- $.repo }}{{ .data.project }}{{ .data.image }}:{{ .data.version -}}
{{- end -}}
