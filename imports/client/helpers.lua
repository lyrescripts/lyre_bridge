local Core = LyreBridge
local pack = table.pack or function(...)
    return {
        n = select("#", ...),
        ...,
    }
end
local unpack = table.unpack or unpack

local function currentResourceName()
    if type(GetCurrentResourceName) == "function" then
        return GetCurrentResourceName()
    end

    return "unknown"
end

local function pcallExport(resourceName, exportName, ...)
    if not Core.isStarted(resourceName) then
        return false, "resource_not_started"
    end

    local args = pack(...)
    local ok, result = pcall(function()
        return exports[resourceName][exportName](unpack(args, 1, args.n))
    end)

    if not ok then
        return false, result
    end

    return true, result
end

local function getNetworkEntity(netId)
    if NetworkDoesEntityExistWithNetworkId(netId) then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end

    return nil
end

local function waitForNetworkEntity(netId, timeoutMs)
    if type(netId) ~= "number" or netId == 0 then
        return nil
    end

    local startedAt = GetGameTimer()
    timeoutMs = timeoutMs or 2500

    repeat
        local entity = getNetworkEntity(netId)
        if entity then
            return entity
        end

        if timeoutMs <= 0 then
            return nil
        end

        Wait(0)
    until GetGameTimer() - startedAt >= timeoutMs

    return nil
end

local function resolveVehicle(vehicleOrNetId, timeoutMs)
    if type(vehicleOrNetId) ~= "number" or vehicleOrNetId == 0 then
        return nil
    end

    local networkEntity = waitForNetworkEntity(vehicleOrNetId, timeoutMs or 0)
    if networkEntity then
        return networkEntity
    end

    if DoesEntityExist(vehicleOrNetId) then
        return vehicleOrNetId
    end

    return waitForNetworkEntity(vehicleOrNetId, timeoutMs or 2500)
end

local function toArray(value)
    if type(value) ~= "table" then
        return {}
    end

    if value[1] ~= nil then
        return value
    end

    return { value }
end

local function getRequiredFunctions(config, options)
    if type(options.required) == "table" then
        return options.required
    end

    if type(config) == "table" then
        return config.bridgeRequiredClientFunctions
    end

    return nil
end

Core._clientInternals = {
    currentResourceName = currentResourceName,
    pcallExport = pcallExport,
    getNetworkEntity = getNetworkEntity,
    waitForNetworkEntity = waitForNetworkEntity,
    resolveVehicle = resolveVehicle,
    toArray = toArray,
    getRequiredFunctions = getRequiredFunctions,
}
