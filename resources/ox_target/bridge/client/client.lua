--[[
    ox_target compatibility bridge
    Redirects all ox_target export calls to lyre_context
]]

local lyre = exports.lyre_context

-- Track options by resource for cleanup on resource stop
local trackedResources = {}

--[[
    ARGUMENT CONVERSION WRAPPERS

    ox_target and lyre_context use different argument signatures:

    canInteract:
        ox_target: canInteract(entity, distance, coords, name, bone)
        lyre_context: canInteract(ctx) where ctx = {id, type, model, coords, endCoords, normal, netId, serverId}

    onSelect:
        ox_target: onSelect(data) where data = {entity, coords, distance, zone?}
        lyre_context: onSelect(ctx) with same structure as canInteract
]]

-- Calculate distance between player and target
local function getDistanceToCoords(coords)
    if not coords then return 0 end
    local playerCoords = GetEntityCoords(PlayerPedId())
    return #(playerCoords - coords)
end

-- Common ped bones to check for proximity
local pedBones = {
    "SKEL_Head", "SKEL_Neck_1", "SKEL_Spine3", "SKEL_Spine2", "SKEL_Spine1", "SKEL_Spine0",
    "SKEL_L_UpperArm", "SKEL_L_Forearm", "SKEL_L_Hand", "SKEL_R_UpperArm", "SKEL_R_Forearm", "SKEL_R_Hand",
    "SKEL_L_Thigh", "SKEL_L_Calf", "SKEL_L_Foot", "SKEL_R_Thigh", "SKEL_R_Calf", "SKEL_R_Foot"
}

-- Get bone name from entity and endCoords (raycast hit point)
local function getBoneFromHit(entity, endCoords)
    if not entity or entity == 0 or not endCoords then return nil end

    local entityType = GetEntityType(entity)
    if entityType == 1 then -- Ped
        -- Find nearest bone by checking distance to each bone position
        local nearestBone = nil
        local nearestDist = math.huge
        for _, boneName in ipairs(pedBones) do
            local boneIndex = GetEntityBoneIndexByName(entity, boneName)
            if boneIndex ~= -1 then
                local bonePos = GetWorldPositionOfEntityBone(entity, boneIndex)
                local dist = #(endCoords - bonePos)
                if dist < nearestDist then
                    nearestDist = dist
                    nearestBone = boneName
                end
            end
        end
        return nearestBone
    elseif entityType == 2 then -- Vehicle
        -- For vehicles, try to find which bone was hit
        local boneIndex = GetEntityBoneIndexByName(entity, "chassis")
        if boneIndex ~= -1 then
            return "chassis"
        end
    end
    return nil
end

-- Wrap canInteract function to convert lyre_context ctx to ox_target arguments
local function wrapCanInteract(originalCanInteract, optionName)
    if not originalCanInteract then return nil end

    return function(ctx)
        -- Convert lyre_context ctx to ox_target arguments
        -- ox_target: canInteract(entity, distance, coords, name, bone)
        local entity = ctx.id or 0
        local coords = ctx.endCoords or ctx.coords
        local distance = getDistanceToCoords(coords)
        local name = optionName
        local bone = getBoneFromHit(entity, ctx.endCoords)

        return originalCanInteract(entity, distance, coords, name, bone)
    end
end

-- Convert lyre_context ctx to ox_target data format (used for events)
-- optionData: the original option containing custom fields to merge
local function convertCtxToOxData(ctx, zoneId, optionData)
    local coords = ctx.endCoords or ctx.coords
    local data = {
        entity = ctx.id or 0,
        coords = coords,
        distance = getDistanceToCoords(coords),
        zone = zoneId or nil
    }
    -- Merge custom fields from the original option
    if optionData then
        for k, v in pairs(optionData) do
            -- Don't overwrite core fields and skip callback functions
            if data[k] == nil and k ~= "onSelect" and k ~= "canInteract" and k ~= "event" and k ~= "serverEvent" then
                data[k] = v
            end
        end
    end
    return data
end

-- Wrap onSelect function to convert lyre_context ctx to ox_target data format
local function wrapOnSelect(originalOnSelect, zoneId, optionData)
    if not originalOnSelect then return nil end

    return function(ctx)
        -- Convert lyre_context ctx to ox_target data format
        local data = convertCtxToOxData(ctx, zoneId, optionData)
        return originalOnSelect(data)
    end
end

-- Process a single option and wrap its callbacks
local function wrapOptionCallbacks(option, zoneId)
    if not option then return option end

    local wrapped = {}
    for k, v in pairs(option) do
        wrapped[k] = v
    end

    -- Wrap canInteract if present
    if wrapped.canInteract then
        wrapped.canInteract = wrapCanInteract(wrapped.canInteract, wrapped.name)
    end

    -- Wrap onSelect if present
    if wrapped.onSelect then
        wrapped.onSelect = wrapOnSelect(wrapped.onSelect, zoneId, option)
    end

    -- For events (event/serverEvent), we need to convert the data passed
    -- lyre_context passes ctx directly, ox_target expects data = {entity, coords, distance, zone?, ...customFields}
    -- We wrap these by using onSelect which will be called instead of the event directly
    if wrapped.event and not wrapped.onSelect then
        local originalEvent = wrapped.event
        local originalOption = option -- Capture original option for custom fields
        wrapped.event = nil
        wrapped.onSelect = function(ctx)
            local data = convertCtxToOxData(ctx, zoneId, originalOption)
            TriggerEvent(originalEvent, data)
        end
    elseif wrapped.serverEvent and not wrapped.onSelect then
        local originalServerEvent = wrapped.serverEvent
        local originalOption = option -- Capture original option for custom fields
        wrapped.serverEvent = nil
        wrapped.onSelect = function(ctx)
            local data = convertCtxToOxData(ctx, zoneId, originalOption)
            -- For server events, ox_target sends netId instead of entity handle
            if ctx.netId then
                data.entity = ctx.netId
            end
            TriggerServerEvent(originalServerEvent, data)
        end
    end

    return wrapped
end

local function trackForResource(resourceName, category, data)
    if not resourceName then return end

    if not trackedResources[resourceName] then
        trackedResources[resourceName] = {}
    end

    if not trackedResources[resourceName][category] then
        trackedResources[resourceName][category] = {}
    end

    table.insert(trackedResources[resourceName][category], data)
end

-- Cleanup when a resource stops
AddEventHandler('onResourceStop', function(resourceName)
    local tracked = trackedResources[resourceName]
    if not tracked then return end

    -- Clean global options
    if tracked.globalOptions then
        for _, name in ipairs(tracked.globalOptions) do
            lyre:removeGlobalOption(name)
        end
    end

    -- Clean object options
    if tracked.objectOptions then
        for _, name in ipairs(tracked.objectOptions) do
            lyre:removeObjectOption(name)
        end
    end

    -- Clean ped options
    if tracked.pedOptions then
        for _, name in ipairs(tracked.pedOptions) do
            lyre:removePedOption(name)
        end
    end

    -- Clean player options
    if tracked.playerOptions then
        for _, name in ipairs(tracked.playerOptions) do
            lyre:removePlayerOption(name)
        end
    end

    -- Clean vehicle options
    if tracked.vehicleOptions then
        for _, name in ipairs(tracked.vehicleOptions) do
            lyre:removeVehicleOption(name)
        end
    end

    -- Clean model options
    if tracked.modelOptions then
        for _, data in ipairs(tracked.modelOptions) do
            for _, model in ipairs(data.models) do
                lyre:removeModelOption(model, data.name)
            end
        end
    end

    -- Clean local entity options
    if tracked.localEntityOptions then
        for _, data in ipairs(tracked.localEntityOptions) do
            for _, entity in ipairs(data.entities) do
                if DoesEntityExist(entity) then
                    lyre:removeLocalEntityOption(entity, data.name)
                end
            end
        end
    end

    -- Clean zones
    if tracked.zones then
        for _, zoneId in ipairs(tracked.zones) do
            lyre:removeZoneOption(zoneId)
        end
    end

    trackedResources[resourceName] = nil
    print(('[ox_target bridge] Cleaned up options for resource: %s'):format(resourceName))
end)

-- Helper function to process options for lyre_context format
-- Also wraps canInteract and onSelect callbacks to convert arguments
local function processOptions(options, zoneId)
    if not options then return {} end

    -- Detect if single option or array of options
    local isSingleOption = options[1] == nil and (options.label or options.onSelect or options.event or options.serverEvent or options.export or options.command)
    local optionsList = isSingleOption and {options} or options

    -- Wrap callbacks for each option
    local wrappedOptions = {}
    for i, option in ipairs(optionsList) do
        wrappedOptions[i] = wrapOptionCallbacks(option, zoneId)
    end

    return wrappedOptions
end

-- Helper to get option names from result
local function getOptionNames(result)
    if type(result) == "table" then
        return result
    elseif result then
        return {result}
    end
    return {}
end

--[[
    DISABLE TARGETING
]]
exports("disableTargeting", function(state)
    return lyre:disableTargeting(state)
end)

--[[
    GLOBAL OPTIONS
]]
exports("addGlobalOption", function(options)
    local resource = GetInvokingResource()
    local result = lyre:addGlobalOption(processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "globalOptions", name)
    end
    return result
end)

exports("removeGlobalOption", function(optionNames)
    if type(optionNames) == "table" then
        for _, name in ipairs(optionNames) do
            lyre:removeGlobalOption(name)
        end
    else
        lyre:removeGlobalOption(optionNames)
    end
end)

--[[
    GLOBAL OBJECT
]]
exports("addGlobalObject", function(options)
    local resource = GetInvokingResource()
    local result = lyre:addObjectOption(processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "objectOptions", name)
    end
    return result
end)

exports("removeGlobalObject", function(optionNames)
    if type(optionNames) == "table" then
        for _, name in ipairs(optionNames) do
            lyre:removeObjectOption(name)
        end
    else
        lyre:removeObjectOption(optionNames)
    end
end)

--[[
    GLOBAL PED
]]
exports("addGlobalPed", function(options)
    local resource = GetInvokingResource()
    local result = lyre:addPedOption(processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "pedOptions", name)
    end
    return result
end)

exports("removeGlobalPed", function(optionNames)
    if type(optionNames) == "table" then
        for _, name in ipairs(optionNames) do
            lyre:removePedOption(name)
        end
    else
        lyre:removePedOption(optionNames)
    end
end)

--[[
    GLOBAL PLAYER
]]
exports("addGlobalPlayer", function(options)
    local resource = GetInvokingResource()
    local result = lyre:addPlayerOption(processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "playerOptions", name)
    end
    return result
end)

exports("removeGlobalPlayer", function(optionNames)
    if type(optionNames) == "table" then
        for _, name in ipairs(optionNames) do
            lyre:removePlayerOption(name)
        end
    else
        lyre:removePlayerOption(optionNames)
    end
end)

--[[
    GLOBAL VEHICLE
]]
exports("addGlobalVehicle", function(options)
    local resource = GetInvokingResource()
    local result = lyre:addVehicleOption(processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "vehicleOptions", name)
    end
    return result
end)

exports("removeGlobalVehicle", function(optionNames)
    if type(optionNames) == "table" then
        for _, name in ipairs(optionNames) do
            lyre:removeVehicleOption(name)
        end
    else
        lyre:removeVehicleOption(optionNames)
    end
end)

--[[
    MODEL
]]
exports("addModel", function(models, options)
    local resource = GetInvokingResource()
    -- Convert models to table if necessary
    local modelsList = (type(models) == "string" or type(models) == "number") and {models} or models
    local result = lyre:addModelOption(modelsList, processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "modelOptions", { models = modelsList, name = name })
    end
    return result
end)

exports("removeModel", function(models, optionNames)
    local modelsList = (type(models) == "string" or type(models) == "number") and {models} or models
    local namesList = type(optionNames) == "table" and optionNames or {optionNames}

    for _, model in ipairs(modelsList) do
        for _, name in ipairs(namesList) do
            lyre:removeModelOption(model, name)
        end
    end
end)

--[[
    LOCAL ENTITY
]]
exports("addLocalEntity", function(entities, options)
    local resource = GetInvokingResource()
    local entitiesList = type(entities) == "number" and {entities} or entities
    local result = lyre:addLocalEntityOption(entitiesList, processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "localEntityOptions", { entities = entitiesList, name = name })
    end
    return result
end)

exports("removeLocalEntity", function(entities, optionNames)
    local entitiesList = type(entities) == "number" and {entities} or entities

    -- If no optionNames provided, remove all options from the entity
    if optionNames == nil then
        for _, entity in ipairs(entitiesList) do
            lyre:removeLocalEntityOption(entity, nil)
        end
        return
    end

    local namesList = type(optionNames) == "table" and optionNames or {optionNames}

    for _, entity in ipairs(entitiesList) do
        for _, name in ipairs(namesList) do
            lyre:removeLocalEntityOption(entity, name)
        end
    end
end)

--[[
    NETWORKED ENTITY (converts netIds to entity handles)
]]
exports("addEntity", function(netIds, options)
    local resource = GetInvokingResource()
    if type(netIds) == "number" then
        netIds = {netIds}
    end

    local entities = {}
    for _, netId in ipairs(netIds) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            table.insert(entities, entity)
        end
    end

    if #entities == 0 then
        return nil
    end

    local result = lyre:addLocalEntityOption(entities, processOptions(options))
    for _, name in ipairs(getOptionNames(result)) do
        trackForResource(resource, "localEntityOptions", { entities = entities, name = name })
    end
    return result
end)

exports("removeEntity", function(netIds, optionNames)
    if type(netIds) == "number" then
        netIds = {netIds}
    end

    local namesList = type(optionNames) == "table" and optionNames or {optionNames}

    for _, netId in ipairs(netIds) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            for _, name in ipairs(namesList) do
                lyre:removeLocalEntityOption(entity, name)
            end
        end
    end
end)

--[[
    ZONES
    ox_target: addSphereZone({ coords, name?, radius?, debug?, drawSprite?, options })
    ox_target: addBoxZone({ coords, name?, size?, rotation?, debug?, drawSprite?, options })
    ox_target: addPolyZone({ points, name?, thickness?, debug?, drawSprite?, options })
]]
exports("addSphereZone", function(parameters)
    local resource = GetInvokingResource()
    local zoneId = parameters.name
    local coords = parameters.coords
    local radius = parameters.radius or 2.0
    local options = parameters.options
    local debug = parameters.debug or false

    local result = lyre:addSphereZoneOption(zoneId, coords, radius, processOptions(options, zoneId), debug)
    -- result is zoneId (first return value)
    if result then
        trackForResource(resource, "zones", result)
    end
    return result
end)

exports("addBoxZone", function(parameters)
    local resource = GetInvokingResource()
    local zoneId = parameters.name
    local coords = parameters.coords
    local size = parameters.size or vector3(2.0, 2.0, 2.0)
    local rotation = parameters.rotation or 0.0
    local options = parameters.options
    local debug = parameters.debug or false

    local result = lyre:addBoxZoneOption(zoneId, coords, size, rotation, processOptions(options, zoneId), debug)
    if result then
        trackForResource(resource, "zones", result)
    end
    return result
end)

exports("addPolyZone", function(parameters)
    local resource = GetInvokingResource()
    local zoneId = parameters.name
    local points = parameters.points
    local thickness = parameters.thickness or 4.0
    local options = parameters.options
    local debug = parameters.debug or false

    local result = lyre:addPolyZoneOption(zoneId, points, thickness, processOptions(options, zoneId), debug)
    if result then
        trackForResource(resource, "zones", result)
    end
    return result
end)

exports("removeZone", function(id)
    lyre:removeZoneOption(id)
end)
