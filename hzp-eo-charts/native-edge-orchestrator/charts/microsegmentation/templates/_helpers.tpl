{{/*
Function to determine if infra pod needs egress access to outside the cluster
Currently only istio-system pod needs this
*/}}
{{- define "infra.pod.egress.expose" -}}
{{- $enableExternalAccess := "false" -}}
{{- if and (eq "istio-system" $.service) (eq (include "external.services.used" (dict "global" $.global)) "true") -}}
  {{- $enableExternalAccess = "true" -}}
{{- end -}}
{{- $enableExternalAccess -}}
{{- end -}}

{{/*
Function to check if eo uses any external services instead of deploying its own
*/}}
{{- define "external.services.used" -}}
{{- $externalServicesUsed := "false" -}}
{{- $postgressInternal := $.global.postgresql.deploy }}
{{- $vaultInternal := $.global.vault.deploy }}
{{- $keycloakInternal := $.global.keycloak.deploy }}
{{- if or (not $postgressInternal) (not $vaultInternal) (not $keycloakInternal) }}
    {{- $externalServicesUsed = "true" -}}
{{- end -}}
{{- $externalServicesUsed -}}
{{- end -}}

{{- define "enable.inbound.external.access" -}}
{{- $enableExternalAccess := "false" -}}
{{- if or (eq .netpol.externalInternetTraffic "inbound") (eq .netpol.externalInternetTraffic "bidirectional") .global.ingress.enableNetworkPoliciesForSmokeTest -}}
  {{- $enableExternalAccess = "true" -}}
{{- else -}}
  {{- range $k, $v := .netpol.inboundRequests -}}
    {{- range $kk, $vv := $v -}}
      {{- if and (eq $vv "postgresql") (not $.global.postgresql.deploy) -}}
      {{- $enableExternalAccess = "true" -}}
      {{- else if and (eq $vv "eo-vault") (not $.global.vault.deploy) -}}
      {{- $enableExternalAccess = "true" -}}
      {{- else if and (eq $vv "keycloak") (not $.global.keycloak.deploy) -}}
      {{- $enableExternalAccess = "true" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $enableExternalAccess -}}
{{- end -}}

{{- define "enable.outbound.external.access" -}}
{{- $enableExternalAccess := "false" -}}
{{- if or (eq .netpol.externalInternetTraffic "outbound") (eq .netpol.externalInternetTraffic "bidirectional") .global.ingress.enableNetworkPoliciesForSmokeTest -}}
  {{- $enableExternalAccess = "true" -}}
{{- else -}}
  {{- range $k, $v := .netpol.outboundRequests -}}
    {{- range $kk, $vv := $v -}}
      {{- if and (eq $vv "postgresql") (not $.global.postgresql.deploy) -}}
      {{- $enableExternalAccess = "true" -}}
      {{- else if and (eq $vv "eo-vault") (not $.global.vault.deploy) -}}
      {{- $enableExternalAccess = "true" -}}
      {{- else if and (eq $vv "keycloak") (not $.global.keycloak.deploy) -}}
      {{- $enableExternalAccess = "true" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $enableExternalAccess -}}
{{- end -}}

