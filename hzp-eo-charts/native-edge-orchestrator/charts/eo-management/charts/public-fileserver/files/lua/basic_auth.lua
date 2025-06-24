{{- $fusionSecretSvc := tpl .Values.fusion.secretsSvc.url . -}}
{{- $tenant := .Values.fusion.secretsSvc.tenant -}}

local authEndpoint = "/api/v3.1/secrets/public-fileserver-auth"
local cache = ngx.shared.lua_cache
local cache_key = "credentials"
local cache_ttl = 600

local function unauthorized_response(message)
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.header["WWW-Authenticate"] = 'Basic realm="Restricted Area"'
    ngx.say(message)
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local function load_credentials()
    {{ printf "local fusionSecretSvc=\"%s\"" $fusionSecretSvc | trim }}
    {{ printf "local tenant=\"%s\"" $tenant | trim }}
    local httpc = require "resty.http"
    local http = httpc.new()
    local fusion_auth = os.getenv("FUSION_AUTH")
    if not fusion_auth or fusion_auth == "" then
        ngx.log(ngx.ERR, "FUSION_AUTH is not set")
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    local auth = "Basic " .. fusion_auth
    local res, err = http:request_uri(fusionSecretSvc .. authEndpoint, {
        method = "GET",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = auth,
            ["Tenant"] = tenant,
        },
        timeout = 25000
    })

    if not res then
        ngx.log(ngx.ERR, "Failed to request auth service: ", err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if res.status ~= 200 then
        ngx.log(ngx.ERR, "Auth service returned non-200 status: ", res.status)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    return res.body
end

local function get_credentials()
    local credential = cache:get(cache_key)
    if credential then
        ngx.log(ngx.INFO, "Load credential from cache")
        return credential
    end

    ngx.log(ngx.INFO, "Load credential from secrets-svc")
    local credsBody = load_credentials()
    credential = credsBody:match('"value":"([^"]+)"')
    cache:set(cache_key, credential, cache_ttl)
    return credential
end

-- Validate Basic Auth
local function validate_auth()
    local headers = ngx.req.get_headers()
    if not headers then
        unauthorized_response("Unauthorized: Missing headers")
    end

    local auth_header = headers["Authorization"]
    if not auth_header then
        unauthorized_response("Unauthorized: Missing Authorization header")
    end

    if not auth_header:find("^Basic ") then
        unauthorized_response("Unauthorized: Basic authorization required")
    end

    local credential = auth_header:sub(7)
    local auth_value = get_credentials()
    if credential ~= auth_value then
        unauthorized_response("Unauthorized: Credentials do not match")
    end

    ngx.log(ngx.INFO, "Authorization successful")

end

-- Call validation function
validate_auth()
