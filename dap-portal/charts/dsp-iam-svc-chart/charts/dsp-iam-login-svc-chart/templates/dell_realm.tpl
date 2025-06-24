{{- define "dell_realm_json" }}
{{- $base := include "base_realm_json" (dict "REALM_NAME" "dell_technologies" "REALM_DISPLAY_NAME" "Dell Technologies" "KEYCLOAK_AUTH_CLIENT_PWD" "${KEYCLOAK_AUTH_CLIENT_PWD}" "KEYCLOAK_AUTOMATION_CLIENT_NAME" "${KEYCLOAK_AUTOMATION_CLIENT_NAME}" "KEYCLOAK_AUTOMATION_CLIENT_PWD" "${KEYCLOAK_AUTOMATION_CLIENT_PWD}") -}}
{{- $base | trimSuffix "}" -}},
  "users": [
    {
      "username": "Administrator",
      "enabled": true,
      "credentials": [
        {
          "type": "password",
          "value": "${DELL_SECURITY_ADMIN_USR_PWD}"
        }
      ],
      {{- if $.Values.global.keycloak.settings.forceAdminUserPostFirstLoginActions }}
      "requiredActions": [
        "UPDATE_PASSWORD",
        "UPDATE_PROFILE"
      ],
      {{- end }}
      "access": {
        "manageGroupMembership": true,
        "view": true,
        "mapRoles": true,
        "impersonate": true,
        "manage": true
      },
      "attributes": {
        "initial_admin": [
          "true"
        ],
        "EMAIL_OTP_ENABLED": [
          "false"
        ],
        "agreement_acceptance": [
          "{{ now | unixEpoch }}"
        ],
        "exposedUser": [
          "true"
        ],
        "storage": [
          "LOCAL"
        ]
      },
      "realmRoles": [
        "Dell Contributor",
        "Dell Editor",
        "Dell Viewer"
      ]
    }
  ],
  "roles": {
    "realm": [
       {
        "name": "Dell Administrator",
        "composite": false,
        "clientRole": false,
        "containerId": "dell_technologies",
        "attributes": {
          "roletype": [
            "default"
          ]
        }
      },
      {
        "name": "Dell Contributor",
        "composite": false,
        "clientRole": false,
        "containerId": "dell_technologies",
        "attributes": {
          "roletype": [
            "default"
          ]
        }
      },
      {
        "name": "Dell Editor",
        "composite": false,
        "clientRole": false,
        "containerId": "dell_technologies",
        "attributes": {
          "roletype": [
            "default"
          ]
        }
      },
      {
        "name": "Dell Viewer",
        "composite": false,
        "clientRole": false,
        "containerId": "dell_technologies",
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
