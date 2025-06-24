{{- define "generic_realm_json" }}
{{- $base := include "base_realm_json" (dict "REALM_NAME" "${REALM_NAME}" "REALM_DISPLAY_NAME" "${REALM_DISPLAY_NAME}" "KEYCLOAK_AUTH_CLIENT_PWD" "${KEYCLOAK_AUTH_CLIENT_PWD}" "KEYCLOAK_AUTOMATION_CLIENT_NAME" "${KEYCLOAK_AUTOMATION_CLIENT_NAME}" "KEYCLOAK_AUTOMATION_CLIENT_PWD" "${KEYCLOAK_AUTOMATION_CLIENT_PWD}") -}}
{{- $base | trimSuffix "}" -}},
  "users": [
    {
      "username": "service-account-${KEYCLOAK_AUTOMATION_CLIENT_NAME}",
      "enabled": true,
      "serviceAccountClientId": "${KEYCLOAK_AUTOMATION_CLIENT_NAME}",
      "realmRoles": ["Administrator"]
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
    ]
  }
}
{{- end }}