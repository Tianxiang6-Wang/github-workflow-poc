{{/*
Function to get full image names from a pipeline manifest
*/}}

{{- define "global.repo" -}}
    {{- printf  "%s%s" .Values.global.repository  -}}
{{- end -}}


{{- define "iam.proxy.sidecar.spec" -}}
{{ $proxyContainer := .Values.proxyContainer }}
{{ $proxyConfig := .Values.proxyConfig }}

name: {{ $proxyContainer.name }}
image: "{{ .Values.global.registry }}{{ .Values.proxyContainer.image.name }}:{{ .Values.proxyContainer.image.tag | default "latest" }}"
imagePullPolicy: {{ $proxyContainer.image.pullPolicy }}
resources:
  limits:
    cpu: 500m
    memory: 250Mi
  requests:
    cpu: 10m
    memory: 25Mi
readinessProbe:
    failureThreshold: 30
    httpGet:
      path: /admin/health/dependency
      port: {{ $proxyConfig.healthCheckPort }}
      scheme: HTTP
    initialDelaySeconds: 1
    periodSeconds: 3
    successThreshold: 1
    timeoutSeconds: 1
securityContext:
    runAsUser: 1447
    runAsGroup: 1447
envFrom:
  - secretRef:
      name: {{ .Values.proxyConfig.initCertSecretName }}
      optional: true
env:
    - name: APP_PORT
      value: "{{ $proxyConfig.port }}"
    - name: ISTIO_DISABLED
      value: "{{ .Values.global.nginx_gw.enabled }}"
    - name: POLICY_SERVICE_BUNDLE_PATH
      value: "http://dsp-iam-policy-svc/api/v1/bundles"
    - name: KEYS_PROVIDER_URL
      value: http://dsp-iam-token-svc
    - name: RELEASE_NAMESPACE
      value: "{{ .Release.Namespace }}"
    - name: SKIP_AUTHNZ_FOR_URIs
      value: "/api/v3.1/file-server-auth,/file-server,/rest/v1/emails/send"
    - name: APP_OUTGOING_PORT
      value: "{{ $proxyConfig.outPort }}"
    - name: DESTINATION_PORT
      value: "{{ $proxyConfig.destinationPort }}"
    - name: HEALTH_CHECK_PORT
      value: "{{ $proxyConfig.healthCheckPort }}"
    - name: TRUST_DOMAIN
      value: "spiffe://eo.edge.dell.com"
    - name: {{ $proxyConfig.externalRequestHeaderName }}
      value: "{{ $proxyConfig.externalRequestHeader }}"
{{- end -}}


{{- define "iam.proxy.initContainer.spec" -}}
{{ $initContainer := .Values.initContainer }}
name: {{ $initContainer.name }}
image: "{{ .Values.global.registry }}{{ .Values.initContainer.image.name }}:{{ .Values.initContainer.image.tag | default "latest" }}"
imagePullPolicy: {{ $initContainer.image.pullPolicy }}
securityContext:
    capabilities:
          add:
            - NET_ADMIN
            - NET_RAW
          drop:
            - ALL
    privileged: false
    runAsUser: 0
    runAsGroup: 0
    runAsNonRoot: false
    readOnlyRootFilesystem: false
    allowPrivilegeEscalation: false
command:
    - 'init.sh'
args:
    - '-p'
    - '15001'
    - '-z'
    - '15006'
    - '-u'
    - '1447'
    - '-m'
    - REDIRECT
{{- end -}}

{{- define "iam.proxy.bundleInitContainer.spec" -}}
{{ $bundleInitContainer := .Values.bundleInitContainer }}
name: {{ $bundleInitContainer.name }}
imagePullPolicy: {{ $bundleInitContainer.image.pullPolicy }}
command:
  - sh
  - -c
  - |
    echo 'Copying bundle files'
    for pair in $FILES_LIST; do
        src=`echo $pair | cut -d ':' -f 1`
        dest=`echo $pair | cut -d ':' -f 2`
        echo "Copying $src to destination $dest"
        mkdir -p $(dirname "$dest") && cp "$src" "$dest"
    done
    echo 'Finished copy of bundle files'

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
