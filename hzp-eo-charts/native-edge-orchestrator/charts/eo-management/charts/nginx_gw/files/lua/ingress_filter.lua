{{- $portalEnabled := and .Values.global.dsp.enabled .Values.global.dsp.portal.enabled -}}
{{- $isSaasEnv := (index .Values.global "is-saas-env") -}}

local sessionSvcDomain="{{ ternary (printf "dsp-iam-session-svc.%s" .Values.global.dsp.portal.namespace) (printf "hzp-iam-session-svc.%s" .Release.Namespace) $portalEnabled }}.svc.cluster.local"
local iamV2AuthZEnabled="{{ .Values.global.iamV2AuthZEnabled }}"

local callbackEndpoint = "/api/v2/auth/callback"
local sessionValidationEndpoint = "/api/v2/auth/validate"
local createTokenV3Endpoint = "/api/v3/auth/tokens"
local createTokenV4Endpoint = "/api/v4/auth/tokens"
local createTokenV5Endpoint = "/api/v5/auth/tokens"
local gatewayTokenV3Endpoint = "/rest/v2/api-token"
local tokenCreateV1Endpoint = "/api/v1/oidc/token"
local keycloakBaseUrl = "{{ ternary (printf "%s/auth/realms/%s" .Values.global.dsp.portal.url .Values.global.dsp.portal.orgId) "/auth/realms/hzp" $portalEnabled }}"
local keycloakAuthEndpoint = keycloakBaseUrl .. "/protocol/openid-connect/auth"
local keycloakCodeToTokenEndpoint = keycloakBaseUrl .. "/protocol/openid-connect/token"
local keycloakExcludePath = "/auth"
local orgName = "{{ .Values.global.staticOnPremOrgId }}"

local authClientId = "{{ ternary .Values.global.dsp.di.clientId .Values.global.dsp.onPrem.clientId $isSaasEnv }}"
local baseUrl = "{{ ternary .Values.global.dsp.di.baseUrl (printf "%s%s%s" .Values.global.dsp.portal.url .Values.global.dsp.onPrem.baseUrl .Values.global.staticOnPremOrgId) $isSaasEnv }}"
local authPath = "{{ ternary .Values.global.dsp.di.authPath .Values.global.dsp.onPrem.authPath $isSaasEnv }}"
local authEndpoint = baseUrl .. authPath

local skippedUrls = { keycloakAuthEndpoint,
                ".css", ".html", ".js", ".js.map",".json", ".png", ".ico", ".jpeg", ".jpg",".svg", ".ttf"
}

local skippedApiUrls = {callbackEndpoint,
                  sessionValidationEndpoint,
                  createTokenV3Endpoint,
                  createTokenV4Endpoint,
                  createTokenV5Endpoint,
                  gatewayTokenV3Endpoint,
                  tokenCreateV1Endpoint
}
local skippedStartWithUrls = {keycloakExcludePath, "/portal"}

{{- $updatedmTLSHostList := include "GetMTLSHostList" (dict "namespace" .Release.Namespace "fqdn" $.Values.global.ingress.fqdn "prefix" $.Values.global.istio.defaultPrefix.mTLSHost "default" $.Values.global.istio.mTLSHost) }}
{{- $updatedmTLSHostList = print "mtls: \n " $updatedmTLSHostList | fromYaml }}
{{- $mtlsHost := join "\", \"" $updatedmTLSHostList.mtls -}}
{{- $updatedmTLSHostRecoveryList := include "GetMTLSHostList" (dict "namespace" .Release.Namespace "fqdn" $.Values.global.ingress.fqdn "prefix" $.Values.global.istio.defaultPrefix.mTLSHostRecovery "default" $.Values.global.istio.mTLSHostRecovery) }}
{{- $updatedmTLSHostRecoveryList = print "mtlsRecovery: \n " $updatedmTLSHostRecoveryList | fromYaml }}
{{- $mtlsHostRecovery := join "\", \"" $updatedmTLSHostRecoveryList.mtlsRecovery -}}
{{- $mtlsHostHeaders := printf "%s\", \"%s" $mtlsHost $mtlsHostRecovery  -}}

{{- $skippedFidoUrl := join "\", \"" .Values.iam.skippedFidoUrl -}}
{{- $skippedInternalUrl := join "\", \"" .Values.iam.skippedInternalUrl -}}
{{- $skippedQAUrl := join "\", \"" .Values.iam.skippedQAUrl }}
{{- $skippedContainerRegistryUrl := join "\", \"" .Values.iam.skippedContainerRegistryUrl -}}
{{- $skippedFileserverUrl := join "\", \"" .Values.iam.skippedFileserverUrl -}}

{{ printf "local mtlsHostHeaders={\"%s\"}" $mtlsHostHeaders | trim }}
{{ printf "local skippedFidoUrl={\"%s\"}" $skippedFidoUrl | trim }}
{{- if $.Values.global.ingress.exposeEOServices }}
   {{ printf "local skippedInternalUrl={\"%s\"}" $skippedInternalUrl | trim }}
{{- else }}
  {{ printf "local skippedInternalUrl={}" | trim }}
{{- end }}
{{- if $.Values.global.exposeQAServices }}
   {{ printf "local skippedQAUrl={\"%s\"}" $skippedQAUrl | trim }}
{{- else }}
  {{ printf "local skippedQAUrl={\"/qa\"}" | trim }}
{{- end }}
{{ printf "local skippedContainerRegistryUrl={\"%s\"}" $skippedContainerRegistryUrl | trim }}
{{ printf "local skippedFileserverUrl={\"%s\"}" $skippedFileserverUrl | trim }}

function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields + 1] = c end)
  return fields
end

function getModifiedCookie(cookieHeader, cookieToRemove)
  local cookies = cookieHeader:split("; ")
  local modifiedCookies = {}
  ngx.log(ngx.WARN, "cookieHeader to modify: ", cookieHeader)
  for _, cookie in ipairs(cookies) do
      if not starts_with(cookie, cookieToRemove .. "=") then
          table.insert(modifiedCookies, cookie)
      end
  end
  local modifiedCookie = table.concat(modifiedCookies, "; ")
  ngx.log(ngx.WARN, "modified cookie: ", modifiedCookie)
  return modifiedCookie
end

function starts_with(str, start)
  return str:sub(1, #start) == start
end

local function ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

function isAuthZRequired(headers)
  -- Skip mtls host headers
  local host_header = headers["host"]
  for _, value in ipairs(mtlsHostHeaders) do
      if starts_with(host_header, value) or ends_with(host_header, value) then
          return false
      end
  end

  -- Add fido URLs to be skipped
  for _, url in ipairs(skippedFidoUrl) do
      table.insert(skippedUrls, url)
  end

  -- Add filer URLs to be skipped
  for _, url in ipairs(skippedFileserverUrl) do
     table.insert(skippedUrls, url)
  end

  -- Add internal URLs to be skipped
  for _, url in ipairs(skippedInternalUrl) do
      table.insert(skippedUrls, url)
  end

  -- Add QA URLs to be skipped
  for _, url in ipairs(skippedQAUrl) do
      table.insert(skippedUrls, url)
  end

  -- Add container registry URLs to be skipped
  for _, url in ipairs(skippedContainerRegistryUrl) do
    table.insert(skippedUrls, url)
  end

  if starts_with(ngx.var.request_uri, "/api") or starts_with(ngx.var.request_uri, "/rest") then
     for i, value in ipairs(skippedApiUrls) do
        if starts_with(ngx.var.uri, value) or starts_with(ngx.var.request_uri, value) then
           return false
        end
     end
     return true
  end

  for i, value in ipairs(skippedUrls) do
     if starts_with(ngx.var.uri, value) or ends_with(ngx.var.uri, value) then
        return false
      end
      if starts_with(ngx.var.request_uri, value) or ends_with(ngx.var.request_uri, value) then
         return false
      end
  end

  for i, value in ipairs(skippedStartWithUrls) do
     if starts_with(ngx.var.uri, value) or starts_with(ngx.var.request_uri, value)  then
        return false
     end
  end

  return true
end

function callAuthZService(headers, issuer)
  local authzHeader = getHeaderIgnoreCase(headers, "Authorization")
  ngx.log(ngx.WARN, "PATH = " .. ngx.var.uri .. ", REQUEST_PATH = " .. ngx.var.request_uri)
  if authzHeader ~= nil then
      ngx.log(ngx.WARN, "authzHeader present")
      return call(authzHeader, nil, nil, issuer)
  else
      local cookieHeader = headers["cookie"]
      if cookieHeader ~= nil then
          local sessionIdCookieValue = extractCookie(cookieHeader)
          return call(nil, sessionIdCookieValue, nil, issuer)
      end
  end
  return call(nil, nil, nil, issuer)
end

function getHeaderIgnoreCase(headers, targetHeader)
  for header, value in pairs(headers) do
      if string.lower(header) == string.lower(targetHeader) then
          return value
      end
  end
  return nil
end

function extractCookie(cookieHeader)
  local pattern = "session.id" .. "=([^;]+);?"
  local value = cookieHeader:match(pattern)
  return value
end

function call(authzHeader, sessionIdCookieValue, clientCertHeader, issuer)
  local response_status, response_headers, response_body
  local headers = ngx.req.get_headers()
  local initialMethod = headers["method"]
  local initialPath = ngx.var.request_uri
  local session_request_headers = {
    ["method"] = "POST",
    ["uri"] = sessionValidationEndpoint,
    ["host"] = sessionSvcDomain,
    ["iss"] = issuer,
    ["initialMethod"] = initialMethod,
    ["initialPath"] = initialPath
  }
  local performHttpCall
  if clientCertHeader then
      ngx.log(ngx.WARN, "Client cert header present: " .. clientCertHeader)
      session_request_headers["x-forwarded-client-cert"] = clientCertHeader
      performHttpCall = true
  elseif authzHeader then
      ngx.log(ngx.WARN, "Authorization header present: " .. authzHeader)
      session_request_headers["authorization"] = authzHeader
      performHttpCall = true
  elseif sessionIdCookieValue then
      local csrfToken = headers["CSRF-Token"]
      if csrfToken then
          ngx.log(ngx.WARN, "CSRF token: " .. csrfToken)
          session_request_headers["CSRF-Token"] = csrfToken
      end
      ngx.log(ngx.WARN, "Session.id cookie present: " .. sessionIdCookieValue)
      session_request_headers["cookie"] = "session.id=" .. sessionIdCookieValue
      performHttpCall = true
  end

  if performHttpCall then
    local httpc = require("resty.http")
    local http = httpc.new()
    local res, err = http:request_uri("http://" .. sessionSvcDomain .. sessionValidationEndpoint, {
        method = "POST",
        headers = session_request_headers,
        body = "Request from Lua filter",
        timeout = 25000
    })
    if not res then
        ngx.log(ngx.ERR, "Failed to request session service: ", err)
        return
    end
    response_status = res.status
    response_headers = res.headers
    response_body = res.body
  else
     if ngx.var.uri == "/" or ngx.var.request_uri == "/" then
        ngx.log(ngx.WARN, "Request does not have neither token cookie nor authorization header")
        return "redirect_to_login"
      else
          ngx.log(ngx.WARN, "Request does not have neither token cookie nor authorization header")
          return "unauthorized"
      end
  end

  if tonumber(response_status) ~= 200 and initialPath == "/" then
      ngx.log(ngx.WARN, "Authentication for path / failed with status " .. response_status .. ". Response from security service is " .. response_body)
      return "redirect_to_login"
  elseif tonumber(response_status) ~= 200 then
      ngx.log(ngx.WARN, "Authentication for path " .. initialPath .. " failed with status " .. response_status .. ". Response from security service is " .. response_body)
      return "unauthorized"
  else
      ngx.log(ngx.WARN, "Response from SS: " .. response_body)
      return response_body
  end
end


-- NOTE: Moved envoy_on_request func
local authHeaderName = "x-edge-estate-auth"
local initiatorHeaderName = "x-edge-estate-initiator"
ngx.req.clear_header(authHeaderName)
ngx.req.clear_header(initiatorHeaderName)
local cookie_header = ngx.var.http_cookie
if cookie_header then
  local modifiedCookie = getModifiedCookie(cookie_header, authHeaderName)
  ngx.req.set_header("cookie", modifiedCookie)
end
local request_headers = ngx.req.get_headers()
local root_url = "{{ .Values.global.dsp.portal.url }}"
local callbackRedirectUri = root_url .. callbackEndpoint
local iss = root_url
if {{ not $isSaasEnv }} then
    iss = root_url .. keycloakBaseUrl
end
ngx.req.set_header("iss", iss)
-- local isEnabled = iamV2AuthZEnabled:match("%s*=%s*(%w+)")
if iamV2AuthZEnabled == "true" then
   if starts_with(ngx.var.uri, callbackEndpoint) or starts_with(ngx.var.request_uri, callbackEndpoint) then
      local uri_args = ngx.req.get_uri_args()
      if uri_args.redirect_uri == nil then
        uri_args["redirect_uri"] = callbackRedirectUri
        ngx.req.set_uri_args(uri_args)
      end
      return
   elseif isAuthZRequired(ngx.req.get_headers()) then
      local auth_response_body = callAuthZService(ngx.req.get_headers(), iss)
      ngx.header["x-on-prem"] = {{ not $isSaasEnv }}
      local referer = ngx.req.get_headers()["referer"]
      local path = "/home"
      local encoded_state = ngx.encode_base64(path)
      if auth_response_body == "redirect_to_login" then
          ngx.header["Location"] = authEndpoint .. "?response_type=code&client_id=" .. authClientId .. "&redirect_uri=" .. callbackRedirectUri .. "&scope=openid profile&prompt=login&state=" .. ngx.escape_uri(encoded_state)
          ngx.exit(ngx.HTTP_MOVED_TEMPORARILY)
          return
      elseif auth_response_body == "unauthorized" then
          local newBody = "Unauthorized"
          ngx.header["x-login-url"] = authEndpoint .. "?response_type=code&client_id=" .. authClientId .. "&redirect_uri=" .. callbackRedirectUri .. "&scope=openid profile&prompt=login&state=" .. ngx.escape_uri(encoded_state)
          ngx.exit(ngx.HTTP_UNAUTHORIZED)
          return
      else
          ngx.req.set_header(authHeaderName, auth_response_body:sub(2, -3))
          ngx.req.set_header(initiatorHeaderName, auth_response_body:sub(2, -3))
          return
      end
   end
end
