{{- define "internal_realm_json" }}
{{- $services := list -}}
{{- range .Values.global.services }}
{{- if .m2m }}
  {{- $services = append $services . }}
{{- end }}
{{- end }}
{{- $base := include "base_realm_json" (dict "REALM_NAME" "internal" "REALM_DISPLAY_NAME" "internal") -}}
{{- $base | trimSuffix "}" -}},
  "users": [
    {{- $lastIndex := sub (len $services) 1 -}}
    {{- range $index, $service := $services }}
    {
      "username": "internal-service-account-{{ .name }}",
      "enabled": true,
      "serviceAccountClientId": "internal-{{ .name }}",
      "realmRoles": ["internal-{{ .name }}"],
      "emailVerified": false,
      "disableableCredentialTypes": [],
      "notBefore": 0,
      "requiredActions": [],
      "totp": false
    }{{- if ne $index $lastIndex }},{{ end }}
    {{- end }}
  ],
  "roles": {
    "realm": [
      {{- range $services}}
      {
        "name": "internal-{{ .name }}",
        "composite": false,
        "clientRole": true,
        "containerId": "internal",
        "attributes": {
          "roletype": [
            "m2m"
          ]
        }
      },
      {{- end }}
      {
        "name": "internal-security-admin",
        "composite": true,
        "composites": {
          "client": {
            "realm-management": [
              "realm-admin"
            ]
          }
        },
        "clientRole": true,
        "containerId": "internal",
        "attributes": {}
      }
    ]
  },
  "clients": [
    {{- range $services}}
    {
      "clientId": "internal-{{ .name }}",
      "name": "internal-{{ .name }}",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-valid-x509",
      "notBefore": 0,
      "bearerOnly": false,
      "consentRequired": false,
      "standardFlowEnabled": false,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "serviceAccountsEnabled": true,
      "publicClient": false,
      "frontchannelLogout": false,
      "protocol": "openid-connect",
      "redirectUris": [],
      "webOrigins": [],
      "authenticationFlowBindingOverrides": {},
      "nodeReRegistrationTimeout": -1,
      "optionalClientScopes": [],
      "defaultClientScopes": [
       "basic",
        "roles",
        "profile"
      ],
      "fullScopeAllowed": true
    },
    {{- end }}
    {
      "clientId": "internal-client",
      "name": "internal-client",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "redirectUris": [
        "*"
      ],
      "webOrigins": [
        "+"
      ],
      "notBefore": 0,
      "bearerOnly": false,
      "consentRequired": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": false,
      "serviceAccountsEnabled": false,
      "publicClient": true,
      "frontchannelLogout": false,
      "protocol": "openid-connect",
      "defaultClientScopes": [
       "basic",
        "roles"
      ],
      "fullScopeAllowed": true
    }
  ]
}
{{- end }}