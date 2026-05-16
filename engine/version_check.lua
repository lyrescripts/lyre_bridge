---Server-only version check pipeline.
---
---On bridge startup, fetches the file list from the `lyrescripts/versions`
---GitHub repository and, for every entry that maps to a resource present on
---the server (regardless of its current state), compares the local
---`fxmanifest.lua` version against the published manifest.
---
---Disabled when `setr lyre_bridge:checkForUpdates false`.
---
---`bridge.core.checkVersion(resourceName?)` remains exposed for manual
---triggers (admin commands, debug consoles, ...).

local VERSIONS_REPO_LIST_URL = "https://api.github.com/repos/lyrescripts/versions/contents/"
local VERSIONS_REPO_FILE_URL = "https://raw.githubusercontent.com/lyrescripts/versions/main/"

---@param resourceName string
local function checkResource(resourceName)
    local currentVersion = GetResourceMetadata(resourceName, "version", 0)
    if not currentVersion then return end

    PerformHttpRequest(
        VERSIONS_REPO_FILE_URL .. resourceName .. ".json",
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

---Manual entry point. Defaults to the invoking resource. Bypasses the
---auto-check toggle so it always runs when called explicitly.
---@param resourceName? string
function bridge.core.checkVersion(resourceName)
    resourceName = resourceName or GetInvokingResource() or GetCurrentResourceName()
    checkResource(resourceName)
end

CreateThread(function()
    if GetConvar("lyre_bridge:checkForUpdates", "true") == "false" then return end

    PerformHttpRequest(
        VERSIONS_REPO_LIST_URL,
        function(status, responseText)
            if status ~= 200 or not responseText then
                bridge.core.log("warning", "lyre_bridge: unable to fetch published version list (status " .. tostring(status) .. ").", "lyre_bridge")
                return
            end

            local data = json.decode(responseText)
            if type(data) ~= "table" then
                bridge.core.log("warning", "lyre_bridge: unexpected payload while listing published versions.", "lyre_bridge")
                return
            end

            for _, entry in ipairs(data) do
                if type(entry) == "table" and entry.type == "file" and type(entry.name) == "string" and entry.name:sub(-5) == ".json" then
                    local resourceName = entry.name:sub(1, -6)
                    if GetResourceMetadata(resourceName, "version", 0) then
                        checkResource(resourceName)
                    end
                end
            end
        end,
        "GET",
        "",
        { ["User-Agent"] = "lyre_bridge" }
    )
end)
