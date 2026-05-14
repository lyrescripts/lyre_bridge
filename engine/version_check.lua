function bridge.core.checkVersion(resourceName)
    resourceName = resourceName or GetInvokingResource() or GetCurrentResourceName()

    local currentVersion = GetResourceMetadata(resourceName, "version", 0)
    if not currentVersion then
        bridge.core.log("error", "Unable to read version metadata for " .. resourceName .. ".", resourceName)
        return
    end

    PerformHttpRequest(
        "https://raw.githubusercontent.com/lyrescripts/versions/main/" .. resourceName .. ".json",
        function(status, responseText)
            if status ~= 200 or not responseText then
                bridge.core.log("error", "Unable to fetch version info for " .. resourceName .. ".", resourceName)
                return
            end

            local data = json.decode(responseText)
            if not data or not data.current_version or not data.links or not data.links.download or not data.links.support then
                bridge.core.log("error", "Invalid version payload for " .. resourceName .. ".", resourceName)
                return
            end

            local latestVersion = data.current_version
            if currentVersion:gsub("%s+", "") == latestVersion:gsub("%s+", "") then
                return
            end

            bridge.core.log("warning", resourceName .. " is not up to date.", resourceName)
            bridge.core.log("warning", "^1Latest version: ^0" .. latestVersion, resourceName)
            bridge.core.log("warning", "^1Your version: ^0" .. currentVersion, resourceName)
            bridge.core.log("warning", "^1Download: ^0" .. data.links.download, resourceName)
            bridge.core.log("warning", "^1Support: ^0" .. data.links.support, resourceName)

            local changelog = data.changelog and data.changelog[latestVersion]
            if changelog and changelog.changes then
                bridge.core.log("warning", "^3Changelog for " .. latestVersion .. ":^0", resourceName)
                for _, change in ipairs(changelog.changes) do
                    bridge.core.log("warning", "^3- " .. change .. "^0", resourceName)
                end
            end
        end,
        "GET"
    )
end
