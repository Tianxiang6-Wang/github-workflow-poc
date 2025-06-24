{{/*
Create chart name as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "mist-ee" | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "netpol.labels" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "netpol.to-nats" -}}
- to:
  - podSelector:
      matchLabels:
        hzp-role: nats
{{- end -}}
{{- define "netpol.to-kube-system" -}}
- to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: kube-system
{{- end -}}
{{- define "netpol.to-istio-system" -}}
- to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: istio-system
{{- end -}}
{{- define "netpol.to-opensearch" -}}
- to:
  - podSelector:
      matchLabels:
        app: opensearch
  ports:
    - protocol: TCP
      port: 9200
{{- end -}}
{{- define "netpol.to-vminsert" -}}
- to:
  - podSelector:
      matchLabels:
        app: vminsert
  ports:
    - protocol: TCP
      port: 8480
{{- end -}}
{{- define "netpol.to-vmselect" -}}
- to:
  - podSelector:
      matchLabels:
        app: vmselect
  ports:
    - protocol: TCP
      port: 8481
{{- end -}}
{{- define "netpol.to-vmstorage" -}}
- to:
  - podSelector:
      matchLabels:
        app: vmstorage
  ports:
    - protocol: TCP
      port: 8400
    - protocol: TCP
      port: 8401
    - protocol: TCP
      port: 8482
{{- end -}}
{{- define "netpol.to-portal" -}}
- to:
  - podSelector:
      matchLabels:
        app: portal
  ports:
    - protocol: TCP
      port: 8000
{{- end -}}
{{- define "netpol.to-gocky" -}}
- to:
  - podSelector:
      matchLabels:
        app: gocky
  ports:
    - protocol: TCP
      port: 9097
{{- end -}}
{{- define "netpol.to-istiod" -}}
- to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: {{ .Values.global.dsp.portal.namespace | default "dapp" }}
    - ipBlock:
        cidr: 0.0.0.0/0
    - podSelector:
        matchLabels:
          hzp-role: eo-gateway
{{- end -}}
