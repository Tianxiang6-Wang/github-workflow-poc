{{- define "generic_realm_json" }}
{{- $base := include "base_realm_json" (dict "REALM_NAME" "${REALM_NAME}" "REALM_DISPLAY_NAME" "${REALM_DISPLAY_NAME}" "KEYCLOAK_AUTH_CLIENT_PWD" "${KEYCLOAK_AUTH_CLIENT_PWD}" "KEYCLOAK_AUTOMATION_CLIENT_NAME" "${KEYCLOAK_AUTOMATION_CLIENT_NAME}" "KEYCLOAK_AUTOMATION_CLIENT_PWD" "${KEYCLOAK_AUTOMATION_CLIENT_PWD}") -}}
{{- $base | trimSuffix "}" -}},
  "users": [
    {
      "username": "service-account-${KEYCLOAK_AUTOMATION_CLIENT_NAME}",
      "enabled": true,
      "serviceAccountClientId": "${KEYCLOAK_AUTOMATION_CLIENT_NAME}",
      "realmRoles": ["Administrator"
       {{- if $.Values.global.keycloak.dsp.enabled }}
        , "Portal Administrator", "Orchestrator Administrator"
       {{- end}}
       ]
    }
  ],
  "roles": {
    "realm": [
    {
      "name": "Administrator",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Application Admin",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Operational Manager",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Viewer",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    }
    {{- if $.Values.global.keycloak.dsp.enabled }}
    ,{
      "name": "Orchestrator Administrator",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "description": "Orchestrator Administrator predefined role",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Orchestrator Operational Manager",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "description": "Orchestrator Operational Manager predefined role",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Orchestrator Application Admin",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "description": "Orchestrator Application Admin predefined role",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Orchestrator Viewer",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "description": "Orchestrator Viewer predefined role",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Portal Administrator",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "description": "Portal Administrator predefined role",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    },
    {
      "name": "Portal Operational Manager",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "description": "Portal Operational Manager predefined role",
      "attributes": {
        "roletype": [
          "default"
        ]
       }
    },
    {
      "name": "Portal Viewer",
      "composite": false,
      "clientRole": false,
      "containerId": "internal",
      "description": "Portal Viewer predefined role",
      "attributes": {
        "roletype": [
          "default"
        ]
      }
    }
    {{- end}}
    ]
  }
}
{{- end }}