{{- define "base_realm_json" }}
{
  "realm": "{{ .REALM_NAME }}",
  "displayName": "{{ .REALM_DISPLAY_NAME }}",
  "notBefore": 0,
  "defaultSignatureAlgorithm": "RS256",
  "revokeRefreshToken": true,
  "refreshTokenMaxReuse": 5,
  "accessTokenLifespan": 300,
  "resetPasswordAllowed": true,
  "accessTokenLifespanForImplicitFlow": 900,
  "ssoSessionIdleTimeout": 3600,
  "ssoSessionMaxLifespan": 604800,
  "ssoSessionIdleTimeoutRememberMe": 0,
  "ssoSessionMaxLifespanRememberMe": 0,
  "accessCodeLifespan": 60,
  "accessCodeLifespanUserAction": 300,
  "accessCodeLifespanLogin": 1800,
  "enabled": true,
  "bruteForceProtected": true,
  "failureFactor": 5,
  "waitIncrementSeconds": 60,
  "maxFailureWaitSeconds": 1800,
  "quickLoginCheckMilliSeconds": 1000,
  "minimumQuickLoginWaitSeconds": 60,
  "maxDeltaTimeSeconds": 43200,
  "actionTokenGeneratedByUserLifespan": 28800,
  "passwordPolicy": "forceExpiredPasswordChange(90) and notUsername(undefined) and notEmail(undefined) and digits(1) and passwordHistory(5) and lowerCase(1) and upperCase(1) and specialChars(1) and length(8)",
  "groups": [],
  "sslRequired": "external",
  "requiredCredentials": [
    "password"
  ],
  "clients": [
    {
      "clientId": "auth-client",
      "name": "auth-client",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "{{ .KEYCLOAK_AUTH_CLIENT_PWD }}",
      "redirectUris": [
         "/api/v2/auth/callback"
      ],
      "webOrigins": [
        "+"
      ],
      "notBefore": 0,
      "bearerOnly": false,
      "consentRequired": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "serviceAccountsEnabled": false,
      "publicClient": false,
      "frontchannelLogout": false,
      "protocol": "openid-connect",
      "rootUrl": "",
      "authenticationFlowBindingOverrides": {},
      "nodeReRegistrationTimeout": -1,
      "optionalClientScopes": [],
      "protocolMappers": [
        {
          "name": "MiddleNameUserAttribueMapper",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-attribute-mapper",
          "consentRequired": false,
          "config": {
            "user.attribute": "middleName",
            "id.token.claim": "false",
            "access.token.claim": "true",
            "claim.name": "middleName",
            "userinfo.token.claim": "false",
            "jsonType.label": "String"
          }
        },
        {
          "name": "AgreementUserAttribueMapper",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-attribute-mapper",
          "consentRequired": false,
          "config": {
            "user.attribute": "agreement_acceptance",
            "id.token.claim": "false",
            "access.token.claim": "true",
            "claim.name": "agreement_acceptance",
            "userinfo.token.claim": "false",
            "jsonType.label": "String"
          }
        },
        {
          "name": "EnableMFAUserAttributeMapper",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-attribute-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "false",
            "user.attribute": "enableMfa",
            "id.token.claim": "false",
            "access.token.claim": "true",
            "claim.name": "enableMfa",
            "jsonType.label": "boolean"
          }
        },
        {
          "name": "CellPhoneUserAttributeMapper",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-attribute-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "false",
            "user.attribute": "cellPhone",
            "id.token.claim": "false",
            "access.token.claim": "true",
            "claim.name": "cellPhone",
            "jsonType.label": "String"
          }
        },
        {
          "name": "UserEnabledPropertyMapper",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-property-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "false",
            "user.attribute": "enabled",
            "id.token.claim": "false",
            "access.token.claim": "true",
            "claim.name": "enabled",
            "jsonType.label": "boolean"
          }
        },
        {
          "name": "UserDisabledManuallyPropertyMapper",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-property-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "false",
            "user.attribute": "disabled_manually",
            "id.token.claim": "false",
            "access.token.claim": "true",
            "claim.name": "disabled_manually",
            "jsonType.label": "boolean"
          }
        },
        {
          "name": "StorageUserAttributeMapper",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-attribute-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "false",
            "user.attribute": "storage",
            "id.token.claim": "false",
            "access.token.claim": "true",
            "claim.name": "storage",
            "jsonType.label": "String"
          }
        }
      ],
      "defaultClientScopes": [
        "basic",
        "roles",
        "profile",
        "email"
      ],
      "fullScopeAllowed": true
    },
{
      "clientId": "${KEYCLOAK_AUTOMATION_CLIENT_NAME}",
      "name": "${KEYCLOAK_AUTOMATION_CLIENT_NAME}",
      "surrogateAuthRequired": false,
      "enabled": true,
      "alwaysDisplayInConsole": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "${KEYCLOAK_AUTOMATION_CLIENT_PWD}",
      "redirectUris": [
         "/api/v2/auth/callback"
      ],
      "webOrigins": [
        "+"
      ],
      "notBefore": 0,
      "bearerOnly": false,
      "consentRequired": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "serviceAccountsEnabled": true,
      "publicClient": false,
      "frontchannelLogout": false,
      "protocol": "openid-connect",
      "defaultClientScopes": [
        "basic",
        "roles",
        "profile",
        "email"
      ],
      "attributes": {
        "access.token.lifespan": "1800"
      },
      "fullScopeAllowed": true
    }
  ],
  "eventsEnabled": true,
  "eventsListeners": [
    "jboss-logging",
    "eo-event-listener"
  ],
  "enabledEventTypes": [
    "UPDATE_CONSENT_ERROR",
    "SEND_RESET_PASSWORD",
    "GRANT_CONSENT",
    "VERIFY_PROFILE_ERROR",
    "UPDATE_TOTP",
    "REMOVE_TOTP",
    "REVOKE_GRANT",
    "LOGIN_ERROR",
    "CLIENT_LOGIN",
    "RESET_PASSWORD_ERROR",
    "IMPERSONATE_ERROR",
    "CODE_TO_TOKEN_ERROR",
    "CUSTOM_REQUIRED_ACTION",
    "OAUTH2_DEVICE_CODE_TO_TOKEN_ERROR",
    "RESTART_AUTHENTICATION",
    "UPDATE_PROFILE_ERROR",
    "IMPERSONATE",
    "LOGIN",
    "UPDATE_PASSWORD_ERROR",
    "OAUTH2_DEVICE_VERIFY_USER_CODE",
    "CLIENT_INITIATED_ACCOUNT_LINKING",
    "TOKEN_EXCHANGE",
    "REGISTER",
    "LOGOUT",
    "AUTHREQID_TO_TOKEN",
    "DELETE_ACCOUNT_ERROR",
    "CLIENT_REGISTER",
    "IDENTITY_PROVIDER_LINK_ACCOUNT",
    "UPDATE_PASSWORD",
    "DELETE_ACCOUNT",
    "FEDERATED_IDENTITY_LINK_ERROR",
    "CLIENT_DELETE",
    "IDENTITY_PROVIDER_FIRST_LOGIN",
    "VERIFY_EMAIL",
    "CLIENT_DELETE_ERROR",
    "CLIENT_LOGIN_ERROR",
    "RESTART_AUTHENTICATION_ERROR",
    "REMOVE_FEDERATED_IDENTITY_ERROR",
    "EXECUTE_ACTIONS",
    "TOKEN_EXCHANGE_ERROR",
    "PERMISSION_TOKEN",
    "SEND_IDENTITY_PROVIDER_LINK_ERROR",
    "EXECUTE_ACTION_TOKEN_ERROR",
    "SEND_VERIFY_EMAIL",
    "OAUTH2_DEVICE_AUTH",
    "EXECUTE_ACTIONS_ERROR",
    "REMOVE_FEDERATED_IDENTITY",
    "OAUTH2_DEVICE_CODE_TO_TOKEN",
    "IDENTITY_PROVIDER_POST_LOGIN",
    "IDENTITY_PROVIDER_LINK_ACCOUNT_ERROR",
    "UPDATE_EMAIL",
    "OAUTH2_DEVICE_VERIFY_USER_CODE_ERROR",
    "REGISTER_ERROR",
    "REVOKE_GRANT_ERROR",
    "LOGOUT_ERROR",
    "UPDATE_EMAIL_ERROR",
    "EXECUTE_ACTION_TOKEN",
    "CLIENT_UPDATE_ERROR",
    "UPDATE_PROFILE",
    "AUTHREQID_TO_TOKEN_ERROR",
    "FEDERATED_IDENTITY_LINK",
    "CLIENT_REGISTER_ERROR",
    "SEND_VERIFY_EMAIL_ERROR",
    "SEND_IDENTITY_PROVIDER_LINK",
    "RESET_PASSWORD",
    "CLIENT_INITIATED_ACCOUNT_LINKING_ERROR",
    "OAUTH2_DEVICE_AUTH_ERROR",
    "UPDATE_CONSENT",
    "REMOVE_TOTP_ERROR",
    "VERIFY_EMAIL_ERROR",
    "SEND_RESET_PASSWORD_ERROR",
    "CLIENT_UPDATE",
    "IDENTITY_PROVIDER_POST_LOGIN_ERROR",
    "CUSTOM_REQUIRED_ACTION_ERROR",
    "UPDATE_TOTP_ERROR",
    "CODE_TO_TOKEN",
    "VERIFY_PROFILE",
    "GRANT_CONSENT_ERROR",
    "IDENTITY_PROVIDER_FIRST_LOGIN_ERROR"
  ],
  "adminEventsEnabled": true,
  "adminEventsDetailsEnabled": true,
  "loginTheme": "dap",
  "emailTheme": "dap",
  "authenticationFlows": [
    {
      "alias": "Account verification options",
      "description": "Method with which to verity the existing account",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "idp-email-verification",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Verify Existing Account by Re-authentication",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Authentication Options",
      "description": "Authentication options.",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "basic-auth",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "basic-auth-otp",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-spnego",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 30,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Browser - Conditional OTP",
      "description": "Flow to determine if the OTP is required for the authentication",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-otp-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Custom browser",
      "description": "browser based authentication",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": false,
      "authenticationExecutions": [
        {
          "authenticator": "auth-cookie",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-spnego",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "identity-provider-redirector",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 25,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 30,
          "autheticatorFlow": true,
          "flowAlias": "browser - otp forms",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Custom clients",
      "description": "Base authentication for clients",
      "providerId": "client-flow",
      "topLevel": true,
      "builtIn": false,
      "authenticationExecutions": [
        {
          "authenticator": "client-secret",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-jwt",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-secret-jwt",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 30,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-valid-x509",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 41,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Direct Grant - Conditional OTP",
      "description": "Flow to determine if the OTP is required for the authentication",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "direct-grant-validate-otp",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Email OTP",
      "description": "",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": false,
      "authenticationExecutions": [
        {
          "authenticatorConfig": "EmailOTPAttribute",
          "authenticator": "conditional-user-attribute",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 0,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "otp-email-authenticator-provider",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 1,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "First broker login - Conditional OTP",
      "description": "Flow to determine if the OTP is required for the authentication",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-otp-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Handle Existing Account",
      "description": "Handle what to do if there is existing account with same email/username like authenticated identity provider",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "idp-confirm-link",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Account verification options",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Reset - Conditional OTP",
      "description": "Flow to determine if the OTP should be reset or not. Set to REQUIRED to force.",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "reset-otp",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "User creation or linking",
      "description": "Flow for the existing/non-existing user alternatives",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticatorConfig": "create unique user config",
          "authenticator": "idp-create-user-if-unique",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Handle Existing Account",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "Verify Existing Account by Re-authentication",
      "description": "Reauthentication of existing account",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "idp-username-password-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "First broker login - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "browser",
      "description": "browser based authentication",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "auth-cookie",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-spnego",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "identity-provider-redirector",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 25,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 30,
          "autheticatorFlow": true,
          "flowAlias": "forms",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "browser - otp forms",
      "description": "Username, password, otp and other auth forms.",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": false,
      "authenticationExecutions": [
        {
          "authenticator": "auth-username-password-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 11,
          "autheticatorFlow": true,
          "flowAlias": "Email OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "clients",
      "description": "Base authentication for clients",
      "providerId": "client-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "client-secret",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-jwt",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-secret-jwt",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 30,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-x509",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 40,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "direct grant",
      "description": "OpenID Connect Resource Owner Grant",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "direct-grant-validate-username",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "direct-grant-validate-password",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 30,
          "autheticatorFlow": true,
          "flowAlias": "Direct Grant - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "docker auth",
      "description": "Used by Docker clients to authenticate against the IDP",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "docker-http-basic-authenticator",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "first broker login",
      "description": "Actions taken after first broker login with identity provider account, which is not yet linked to any Keycloak account",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticatorConfig": "review profile config",
          "authenticator": "idp-review-profile",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "User creation or linking",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "forms",
      "description": "Username, password, otp and other auth forms.",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "auth-username-password-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Browser - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "http challenge",
      "description": "An authentication flow based on challenge-response HTTP Authentication Schemes",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "no-cookie-redirect",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Authentication Options",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "registration",
      "description": "registration flow",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "registration-page-form",
          "authenticatorFlow": true,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": true,
          "flowAlias": "registration form",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "registration form",
      "description": "registration form",
      "providerId": "form-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "registration-user-creation",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "registration-profile-action",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 40,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "registration-password-action",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 50,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "registration-recaptcha-action",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 60,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "reset credentials",
      "description": "Reset credentials for a user if they forgot their password or something",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "custom-reset-credentials-choose-user",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "reset-credential-email",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "reset-password",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 30,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 40,
          "autheticatorFlow": true,
          "flowAlias": "Reset - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "alias": "saml ecp",
      "description": "SAML ECP Profile Authentication Flow",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "http-basic-authenticator",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    }
  ],
  "authenticatorConfig": [
    {
      "alias": "EmailOTPAttribute",
      "config": {
        "attribute_expected_value": "true",
        "attribute_name": "EMAIL_OTP_ENABLED"
      }
    },
    {
      "alias": "create unique user config",
      "config": {
        "require.password.update.after.registration": "false"
      }
    },
    {
      "alias": "review profile config",
      "config": {
        "update.profile.on.first.login": "missing"
      }
    }
  ],
  "browserFlow": "Custom browser",
    "attributes": {
  	    "userAuthMode":"local"
    },
  "clientAuthenticationFlow": "Custom clients"
}
{{- end }}