local Core = LyreBridge

Core.registerModule("server", "licenses", function()
    local module = {}

    local function frameworkName(bridge)
        return bridge and bridge.__lyre and bridge.__lyre.framework
    end

    local function resolveLicense(bridge, licenseType)
        local map = bridge and bridge.licenseMap

        if type(map) == "function" then
            return map(licenseType, bridge)
        end

        if type(map) ~= "table" then
            return nil
        end

        return map[licenseType]
    end

    local function getRawPlayer(bridge, source)
        local players = Core.getModule("server", "players")
        return players and players.getRawPlayer(bridge, source)
    end

    local function getMetadata(rawPlayer)
        local playerData = rawPlayer and rawPlayer.PlayerData
        return playerData and playerData.metadata or {}
    end

    local function getMetadataLicenses(metadata)
        return metadata.licences or metadata.licenses or {}
    end

    local function setMetadataLicenses(rawPlayer, licenses)
        if rawPlayer and rawPlayer.Functions and type(rawPlayer.Functions.SetMetaData) == "function" then
            rawPlayer.Functions.SetMetaData("licences", licenses)
            return true
        end

        if rawPlayer and type(rawPlayer.SetMetaData) == "function" then
            rawPlayer:SetMetaData("licences", licenses)
            return true
        end

        return false
    end

    local function respond(callback, value)
        value = value == true

        if type(callback) == "function" then
            callback(value)
        end

        return value
    end

    function module.hasLicense(bridge, source, licenseType, callback)
        local license = resolveLicense(bridge, licenseType)
        if not license then
            return respond(callback, false)
        end

        if frameworkName(bridge) == "ESX" then
            local hasLicense = false
            TriggerEvent("esx_license:checkLicense", source, license, function(result)
                hasLicense = result == true
                respond(callback, hasLicense)
            end)
            return hasLicense
        end

        local rawPlayer = getRawPlayer(bridge, source)
        if not rawPlayer then
            return respond(callback, false)
        end

        local metadata = getMetadata(rawPlayer)
        local licenses = getMetadataLicenses(metadata)
        return respond(callback, licenses[license] == true)
    end

    function module.grantLicense(bridge, source, licenseType)
        local license = resolveLicense(bridge, licenseType)
        if not license then
            return false
        end

        if frameworkName(bridge) == "ESX" then
            local hasLicense = false
            TriggerEvent("esx_license:checkLicense", source, license, function(result)
                hasLicense = result == true
            end)

            if hasLicense then
                return true
            end

            TriggerEvent("esx_license:addLicense", source, license)
            return true
        end

        local rawPlayer = getRawPlayer(bridge, source)
        if not rawPlayer then
            return false
        end

        local metadata = getMetadata(rawPlayer)
        local licenses = getMetadataLicenses(metadata)

        if licenses[license] then
            return true
        end

        licenses[license] = true
        return setMetadataLicenses(rawPlayer, licenses)
    end

    return module
end)
