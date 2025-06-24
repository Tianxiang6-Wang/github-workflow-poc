{{- define "hzp_realm_json" }}
{{- $base := include "base_realm_json" (dict "REALM_NAME" "hzp" "REALM_DISPLAY_NAME" "internal") -}}
{{- $base | trimSuffix "}" -}},
  "users": [
      {
        "username": "administrator",
        "enabled": true,
        "credentials": [
          {
            "type": "password",
            "value": "${KEYCLOAK_SECURITY_ADMIN_USR_PWD}"
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
          "exposedUser": [
            "true"
          ],
          "storage": [
            "LOCAL"
          ]
        },
        "realmRoles": [
          "Administrator"
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
    ]
  }
}
{{- end }}