local file = io.open("/etc/nginx/maintenance/maintenanceMode", "r")
local maintenance_mode = file:read("*all")
file:close()

if maintenance_mode == "true" then
    function maintenance_mode_whitelist_check()
        local path = ngx.var.uri
        local whitelisted_paths = {
            "^/api/v2/jobs",
            "^/api/v2/clouds/.*/eula",
            "^/api/v3.1/deployments",
            "^/api/v3/auth/tokens",
            "^/api/v2/upgrade",
            "^/api/v2/endpoints",
            "^/api/v2/proxies"
        }

        for _, pattern in ipairs(whitelisted_paths) do
            if ngx.re.find(path, pattern, "jo") then
                return
            end
        end

        ngx.status = ngx.HTTP_OK
        ngx.say("Maintenance In Progress")
        ngx.exit(ngx.HTTP_OK)
    end

    maintenance_mode_whitelist_check()
end
