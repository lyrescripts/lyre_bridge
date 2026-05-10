local Core = LyreBridge
local VERSION_URL = "https://raw.githubusercontent.com/lyrescripts/versions/main/lyre_bridge.json"

local function normalizeVersion(version)
    return tostring(version or ""):gsub("%s+", "")
end

local function logCheckFailure(message, context)
    Core.log("warn", message or "Unable to check for updates.", context or {
        resource = GetCurrentResourceName(),
    })
end

local function readCurrentVersion()
    local resourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, "version", 0)

    if currentVersion and currentVersion ~= "" then
        return currentVersion
    end

    return Core.versionString()
end

local function decodeVersionResponse(responseText)
    if type(responseText) ~= "string" or responseText == "" then
        return nil
    end

    local ok, data = pcall(json.decode, responseText)
    if ok and type(data) == "table" then
        return data
    end

    return nil
end

local function logChangelog(latestVersion, changelog)
    if type(changelog) ~= "table" or type(changelog.changes) ~= "table" then
        return
    end

    Core.log("warn", "Changelog for version " .. latestVersion .. ":")
    for _, change in ipairs(changelog.changes) do
        Core.log("warn", "- " .. tostring(change))
    end
end

local function checkVersion(statusCode, responseText)
    local resourceName = GetCurrentResourceName()

    if statusCode and (statusCode < 200 or statusCode >= 300) then
        logCheckFailure("Unable to check for updates: version endpoint returned HTTP " .. tostring(statusCode) .. ".", {
            resource = resourceName,
            status = statusCode,
        })
        return
    end

    local currentVersion = readCurrentVersion()
    if not currentVersion or currentVersion == "" then
        logCheckFailure("Unable to check for updates: local version is missing.", {
            resource = resourceName,
        })
        return
    end

    local data = decodeVersionResponse(responseText)
    if not data or not data.current_version or not data.links or not data.links.download or not data.links.support then
        logCheckFailure("Unable to check for updates: version response is invalid.", {
            resource = resourceName,
        })
        return
    end

    local latestVersion = data.current_version
    if normalizeVersion(currentVersion) == normalizeVersion(latestVersion) then
        return
    end

    Core.log("warn", resourceName .. " is not up to date.")
    Core.log("warn", "Latest version: " .. latestVersion)
    Core.log("warn", "Your version: " .. currentVersion)
    Core.log("warn", "Download the latest version here: " .. data.links.download)
    Core.log("warn", "Need support? " .. data.links.support)

    logChangelog(latestVersion, data.changelog and data.changelog[latestVersion])
end

function Core.performVersionCheck()
    if type(PerformHttpRequest) ~= "function" then
        return
    end

    PerformHttpRequest(VERSION_URL, checkVersion, "GET")
end
