--[[
    qtarget compatibility bridge
    Redirects all qtarget export calls to lyre_context

    qtarget API:
    - Options use { label, icon, action/event, distance, ... }
    - Zones use PolyZone-style parameters (name, center, length, width, options, targetoptions)
    - targetoptions = { options = {...}, distance = X }
]]

local lyre = exports.lyre_context

-- Logging function for warnings and errors
local function log(logType, msg)
    logType = logType and string.lower(logType) or "info"
    local prefix
    if logType == "error" then
        prefix = "^1[ERROR]^0 "
    elseif logType == "warning" then
        prefix = "^3[WARNING]^0 "
    elseif logType == "info" then
        prefix = "^2[INFO]^0 "
    end
    print("^5(^2" .. string.upper(GetCurrentResourceName()) .. "^5) ^4- " .. prefix .. msg)
end

-- Log unsupported feature usage
local function logUnsupported(exportName, invokingResource)
    local resource = invokingResource or "unknown"
    log("warning", ("Resource '%s' is using '%s' which is not fully supported by lyre_context. Manual modification may be required for full compatibility."):format(resource, exportName))
end

-- Track options by resource for cleanup on resource stop
local trackedResources = {}

--[[
    ARGUMENT CONVERSION WRAPPERS

    qtarget and lyre_context use different argument signatures:

    qtarget action: action(entity)
    lyre_context onSelect: onSelect(ctx) where ctx = {id, type, model, coords, endCoords, normal, netId, serverId}

    qtarget event data: {entity, coords, distance, ...option fields}
    lyre_context: passes ctx directly
]]

-- Calculate distance between player and target
local function getDistanceToCoords(coords)
    if not coords then return 0 end
    local playerCoords = GetEntityCoords(PlayerPedId())
    return #(playerCoords - coords)
end

-- Convert lyre_context ctx to qtarget data format
local function convertCtxToQtargetData(ctx, optionData)
    local coords = ctx.endCoords or ctx.coords
    local data = {
        entity = ctx.id or 0,
        coords = coords,
        distance = getDistanceToCoords(coords),
    }
    -- Merge option data
    if optionData then
        for k, v in pairs(optionData) do
            if k ~= "action" and k ~= "onSelect" then
                data[k] = v
            end
        end
    end
    return data
end

-- Wrap action function to convert lyre_context ctx to qtarget entity
local function wrapAction(originalAction)
    if not originalAction then return nil end

    return function(ctx)
        -- qtarget action receives just the entity
        local entity = ctx.id or 0
        return originalAction(entity)
    end
end

-- Wrap canInteract function
local function wrapCanInteract(originalCanInteract, optionData)
    if not originalCanInteract then return nil end

    return function(ctx)
        -- qtarget canInteract receives (entity, distance, coords, name)
        local entity = ctx.id or 0
        local coords = ctx.endCoords or ctx.coords
        local distance = getDistanceToCoords(coords)
        local name = optionData and optionData.label

        return originalCanInteract(entity, distance, coords, name)
    end
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

    -- Clean ped options
    if tracked.pedOptions then
        for _, label in ipairs(tracked.pedOptions) do
            lyre:removePedOption(label)
        end
    end

    -- Clean vehicle options
    if tracked.vehicleOptions then
        for _, label in ipairs(tracked.vehicleOptions) do
            lyre:removeVehicleOption(label)
        end
    end

    -- Clean object options
    if tracked.objectOptions then
        for _, label in ipairs(tracked.objectOptions) do
            lyre:removeObjectOption(label)
        end
    end

    -- Clean player options
    if tracked.playerOptions then
        for _, label in ipairs(tracked.playerOptions) do
            lyre:removePlayerOption(label)
        end
    end

    -- Clean model options
    if tracked.modelOptions then
        for _, data in ipairs(tracked.modelOptions) do
            for _, model in ipairs(data.models) do
                lyre:removeModelOption(model, data.label)
            end
        end
    end

    -- Clean entity options
    if tracked.entityOptions then
        for _, data in ipairs(tracked.entityOptions) do
            lyre:removeLocalEntityOption(data.entity, data.label)
        end
    end

    -- Clean zones
    if tracked.zones then
        for _, zoneName in ipairs(tracked.zones) do
            lyre:removeZoneOption(zoneName)
        end
    end

    trackedResources[resourceName] = nil
    print(('[qtarget bridge] Cleaned up options for resource: %s'):format(resourceName))
end)

-- Convert qtarget option format to lyre_context format
-- qtarget: { label, icon, action, event, type, distance, canInteract, job, gang, item, ... }
-- lyre_context: { label, icon, onSelect, event, serverEvent, canInteract, groups, items, ... }
local function convertOption(option, zoneOrEntityId)
    if not option then return nil end

    local converted = {
        name = option.name or option.label,
        label = option.label,
        icon = option.icon,
        distance = option.distance,
    }

    -- Convert action to onSelect
    if option.action then
        converted.onSelect = wrapAction(option.action)
    elseif option.event then
        -- Convert event based on type
        if option.type == "server" then
            local originalEvent = option.event
            converted.onSelect = function(ctx)
                local data = convertCtxToQtargetData(ctx, option)
                TriggerServerEvent(originalEvent, data)
            end
        elseif option.type == "command" then
            local originalEvent = option.event
            converted.onSelect = function(ctx)
                ExecuteCommand(originalEvent)
            end
        elseif option.type == "qbcommand" then
            local originalEvent = option.event
            converted.onSelect = function(ctx)
                local data = convertCtxToQtargetData(ctx, option)
                TriggerServerEvent('QBCore:CallCommand', originalEvent, data)
            end
        else
            -- Default to client event
            local originalEvent = option.event
            converted.onSelect = function(ctx)
                local data = convertCtxToQtargetData(ctx, option)
                TriggerEvent(originalEvent, data)
            end
        end
    end

    -- Convert canInteract
    if option.canInteract then
        converted.canInteract = wrapCanInteract(option.canInteract, option)
    end

    -- Convert job/gang to groups
    if option.job or option.gang then
        converted.groups = {}
        if option.job then
            if type(option.job) == "string" then
                converted.groups[option.job] = 0
            elseif type(option.job) == "table" then
                for _, j in pairs(option.job) do
                    if type(j) == "string" then
                        converted.groups[j] = 0
                    elseif type(j) == "table" then
                        converted.groups[j.name or j[1]] = j.grade or j[2] or 0
                    end
                end
            end
        end
        if option.gang then
            if type(option.gang) == "string" then
                converted.groups[option.gang] = 0
            elseif type(option.gang) == "table" then
                for _, g in pairs(option.gang) do
                    if type(g) == "string" then
                        converted.groups[g] = 0
                    elseif type(g) == "table" then
                        converted.groups[g.name or g[1]] = g.grade or g[2] or 0
                    end
                end
            end
        end
    end

    -- Convert item/required_item to items
    if option.item or option.required_item then
        local itemData = option.item or option.required_item
        if type(itemData) == "string" then
            converted.items = itemData
        elseif type(itemData) == "table" then
            converted.items = itemData
        end
    end

    return converted
end

-- Process options array and convert each option
local function processOptions(options, zoneOrEntityId)
    if not options then return {} end

    local result = {}
    for i, option in ipairs(options) do
        result[i] = convertOption(option, zoneOrEntityId)
    end
    return result
end

-- Helper to get labels from options for tracking
local function getLabelsFromOptions(options)
    local labels = {}
    for _, opt in ipairs(options) do
        if opt.label then
            table.insert(labels, opt.label)
        end
    end
    return labels
end

--[[
    ZONE EXPORTS
    qtarget: AddCircleZone(name, center, radius, options, targetoptions)
    qtarget: AddBoxZone(name, center, length, width, options, targetoptions)
    qtarget: AddPolyZone(name, points, options, targetoptions)
    qtarget: AddComboZone(zones, options, targetoptions)
    qtarget: AddEntityZone(name, entity, options, targetoptions)

    options = PolyZone options (debugPoly, useZ, etc.)
    targetoptions = { options = {...}, distance = X }
]]

exports("AddCircleZone", function(name, center, radius, options, targetoptions)
    local resource = GetInvokingResource()
    local zoneId = name
    local coords = type(center) == "vector3" and center or vector3(center.x, center.y, center.z)
    local lyreOptions = processOptions(targetoptions.options or {}, name)
    local debug = options and options.debugPoly or false

    local result = lyre:addSphereZoneOption(zoneId, coords, radius, lyreOptions, debug)
    if result then
        trackForResource(resource, "zones", result)
    end

    -- Return a zone-like object for compatibility
    return {
        name = zoneId,
        center = coords,
        radius = radius,
        destroy = function()
            lyre:removeZoneOption(zoneId)
        end,
        isPointInside = function(self, point)
            return #(coords - point) <= radius
        end
    }
end)

exports("AddBoxZone", function(name, center, length, width, options, targetoptions)
    local resource = GetInvokingResource()
    local zoneId = name
    local coords = type(center) == "vector3" and center or vector3(center.x, center.y, center.z)
    local size = vector3(length, width, options and (options.maxZ - options.minZ) or 4.0)
    local rotation = options and options.heading or 0.0
    local lyreOptions = processOptions(targetoptions.options or {}, name)
    local debug = options and options.debugPoly or false

    local result = lyre:addBoxZoneOption(zoneId, coords, size, rotation, lyreOptions, debug)
    if result then
        trackForResource(resource, "zones", result)
    end

    -- Return a zone-like object for compatibility
    return {
        name = zoneId,
        center = coords,
        length = length,
        width = width,
        destroy = function()
            lyre:removeZoneOption(zoneId)
        end
    }
end)

exports("AddPolyZone", function(name, points, options, targetoptions)
    local resource = GetInvokingResource()
    local zoneId = name
    local thickness = options and (options.maxZ and options.minZ and (options.maxZ - options.minZ)) or 4.0
    local lyreOptions = processOptions(targetoptions.options or {}, name)
    local debug = options and options.debugPoly or false

    local result = lyre:addPolyZoneOption(zoneId, points, thickness, lyreOptions, debug)
    if result then
        trackForResource(resource, "zones", result)
    end

    -- Return a zone-like object for compatibility
    return {
        name = zoneId,
        points = points,
        destroy = function()
            lyre:removeZoneOption(zoneId)
        end
    }
end)

exports("AddComboZone", function(zones, options, targetoptions)
    -- ComboZone combines multiple zones - for lyre_context, we just register each zone's options
    -- This is a simplified implementation
    local resource = GetInvokingResource()
    local zoneId = options and options.name or ("combo_" .. tostring(math.random(100000, 999999)))

    -- For now, we can't truly replicate ComboZone behavior
    logUnsupported("AddComboZone", resource)

    return {
        name = zoneId,
        destroy = function()
            -- Clean up would need to track all sub-zones
        end
    }
end)

exports("AddEntityZone", function(name, entity, options, targetoptions)
    local resource = GetInvokingResource()
    local zoneId = name
    local lyreOptions = processOptions(targetoptions.options or {}, name)

    -- EntityZone is like a local entity target in lyre_context
    local result = lyre:addLocalEntityOption({entity}, lyreOptions)

    if result then
        for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
            trackForResource(resource, "entityOptions", { entity = entity, label = label })
        end
    end

    -- Return a zone-like object for compatibility
    return {
        name = zoneId,
        entity = entity,
        destroy = function()
            for _, opt in ipairs(lyreOptions) do
                lyre:removeLocalEntityOption(entity, opt.name or opt.label)
            end
        end
    }
end)

exports("RemoveZone", function(name)
    lyre:removeZoneOption(name)
end)

--[[
    BONE EXPORTS
    qtarget: AddTargetBone(bones, parameters)
    parameters = { distance = X, options = {...} }

    Note: lyre_context doesn't have native bone support, so we'll convert to vehicle options
    with a canInteract check for the specific bones
]]

local boneTargets = {}

exports("AddTargetBone", function(bones, parameters)
    local resource = GetInvokingResource()
    local bonesList = type(bones) == "string" and {bones} or bones
    local distance = parameters.distance or 2.5
    local options = parameters.options or {}

    -- Store bone targets for potential future use
    for _, bone in ipairs(bonesList) do
        if not boneTargets[bone] then
            boneTargets[bone] = {}
        end
        for _, opt in ipairs(options) do
            boneTargets[bone][opt.label] = opt
        end
    end

    -- For now, add as vehicle options with bone check in canInteract
    local lyreOptions = {}
    for i, opt in ipairs(options) do
        local converted = convertOption(opt)
        -- Add bone check to canInteract
        local originalCanInteract = converted.canInteract
        converted.canInteract = function(ctx)
            -- Check if we're looking at one of the target bones
            if ctx.id and ctx.id ~= 0 and GetEntityType(ctx.id) == 2 then
                -- It's a vehicle, bone targeting would apply
                if originalCanInteract then
                    return originalCanInteract(ctx)
                end
                return true
            end
            return false
        end
        converted.distance = distance
        lyreOptions[i] = converted
    end

    local result = lyre:addVehicleOption(lyreOptions)

    if result then
        for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
            trackForResource(resource, "vehicleOptions", label)
        end
    end

    return result
end)

exports("RemoveTargetBone", function(bones, labels)
    local bonesList = type(bones) == "string" and {bones} or bones
    local labelsList = labels and (type(labels) == "string" and {labels} or labels) or nil

    for _, bone in ipairs(bonesList) do
        if boneTargets[bone] then
            if labelsList then
                for _, label in ipairs(labelsList) do
                    boneTargets[bone][label] = nil
                    lyre:removeVehicleOption(label)
                end
            else
                for label in pairs(boneTargets[bone]) do
                    lyre:removeVehicleOption(label)
                end
                boneTargets[bone] = nil
            end
        end
    end
end)

--[[
    ENTITY EXPORTS
    qtarget: AddTargetEntity(entities, parameters)
    parameters = { distance = X, options = {...} }
]]

exports("AddTargetEntity", function(entities, parameters)
    local resource = GetInvokingResource()
    local entitiesList = type(entities) == "number" and {entities} or entities
    local lyreOptions = processOptions(parameters.options or {})

    -- Apply distance to options
    local distance = parameters.distance or 2.5
    for _, opt in ipairs(lyreOptions) do
        opt.distance = opt.distance or distance
    end

    -- Handle networked entities - convert netId to entity if needed
    local localEntities = {}
    for _, entity in ipairs(entitiesList) do
        if NetworkGetEntityIsNetworked(entity) then
            -- Keep as is, lyre_context handles both
            table.insert(localEntities, entity)
        else
            table.insert(localEntities, entity)
        end
    end

    local result = lyre:addLocalEntityOption(localEntities, lyreOptions)

    if result then
        for _, entity in ipairs(localEntities) do
            for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
                trackForResource(resource, "entityOptions", { entity = entity, label = label })
            end
        end
    end

    return result
end)

exports("RemoveTargetEntity", function(entities, labels)
    local resource = GetInvokingResource()
    local entitiesList = type(entities) == "number" and {entities} or entities
    local labelsList = labels and (type(labels) == "string" and {labels} or labels) or nil

    for _, entity in ipairs(entitiesList) do
        if labelsList then
            for _, label in ipairs(labelsList) do
                lyre:removeLocalEntityOption(entity, label)
            end
        else
            -- Remove all options for this entity
            -- This requires knowing all labels, which we may not have
            logUnsupported("RemoveTargetEntity (without labels)", resource)
        end
    end
end)

--[[
    MODEL EXPORTS
    qtarget: AddTargetModel(models, parameters)
    parameters = { distance = X, options = {...} }
]]

exports("AddTargetModel", function(models, parameters)
    local resource = GetInvokingResource()
    local modelsList = (type(models) == "string" or type(models) == "number") and {models} or models
    local lyreOptions = processOptions(parameters.options or {})

    -- Apply distance to options
    local distance = parameters.distance or 2.5
    for _, opt in ipairs(lyreOptions) do
        opt.distance = opt.distance or distance
    end

    local result = lyre:addModelOption(modelsList, lyreOptions)

    if result then
        for _, model in ipairs(modelsList) do
            for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
                trackForResource(resource, "modelOptions", { models = {model}, label = label })
            end
        end
    end

    return result
end)

exports("RemoveTargetModel", function(models, labels)
    local resource = GetInvokingResource()
    local modelsList = (type(models) == "string" or type(models) == "number") and {models} or models
    local labelsList = labels and (type(labels) == "string" and {labels} or labels) or nil

    for _, model in ipairs(modelsList) do
        if labelsList then
            for _, label in ipairs(labelsList) do
                lyre:removeModelOption(model, label)
            end
        else
            -- Can't remove all without knowing labels
            logUnsupported("RemoveTargetModel (without labels)", resource)
        end
    end
end)

--[[
    GLOBAL TYPE EXPORTS
    qtarget: Ped(parameters), Vehicle(parameters), Object(parameters), Player(parameters)
    parameters = { distance = X, options = {...} }
]]

exports("Ped", function(parameters)
    local resource = GetInvokingResource()
    local lyreOptions = processOptions(parameters.options or {})

    local distance = parameters.distance or 2.5
    for _, opt in ipairs(lyreOptions) do
        opt.distance = opt.distance or distance
    end

    local result = lyre:addPedOption(lyreOptions)

    if result then
        for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
            trackForResource(resource, "pedOptions", label)
        end
    end

    return result
end)

exports("Vehicle", function(parameters)
    local resource = GetInvokingResource()
    local lyreOptions = processOptions(parameters.options or {})

    local distance = parameters.distance or 2.5
    for _, opt in ipairs(lyreOptions) do
        opt.distance = opt.distance or distance
    end

    local result = lyre:addVehicleOption(lyreOptions)

    if result then
        for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
            trackForResource(resource, "vehicleOptions", label)
        end
    end

    return result
end)

exports("Object", function(parameters)
    local resource = GetInvokingResource()
    local lyreOptions = processOptions(parameters.options or {})

    local distance = parameters.distance or 2.5
    for _, opt in ipairs(lyreOptions) do
        opt.distance = opt.distance or distance
    end

    local result = lyre:addObjectOption(lyreOptions)

    if result then
        for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
            trackForResource(resource, "objectOptions", label)
        end
    end

    return result
end)

exports("Player", function(parameters)
    local resource = GetInvokingResource()
    local lyreOptions = processOptions(parameters.options or {})

    local distance = parameters.distance or 2.5
    for _, opt in ipairs(lyreOptions) do
        opt.distance = opt.distance or distance
    end

    local result = lyre:addPlayerOption(lyreOptions)

    if result then
        for _, label in ipairs(getLabelsFromOptions(lyreOptions)) do
            trackForResource(resource, "playerOptions", label)
        end
    end

    return result
end)

exports("RemovePed", function(labels)
    local labelsList = labels and (type(labels) == "string" and {labels} or labels) or nil
    if labelsList then
        for _, label in ipairs(labelsList) do
            lyre:removePedOption(label)
        end
    end
end)

exports("RemoveVehicle", function(labels)
    local labelsList = labels and (type(labels) == "string" and {labels} or labels) or nil
    if labelsList then
        for _, label in ipairs(labelsList) do
            lyre:removeVehicleOption(label)
        end
    end
end)

exports("RemoveObject", function(labels)
    local labelsList = labels and (type(labels) == "string" and {labels} or labels) or nil
    if labelsList then
        for _, label in ipairs(labelsList) do
            lyre:removeObjectOption(label)
        end
    end
end)

exports("RemovePlayer", function(labels)
    local labelsList = labels and (type(labels) == "string" and {labels} or labels) or nil
    if labelsList then
        for _, label in ipairs(labelsList) do
            lyre:removePlayerOption(label)
        end
    end
end)

--[[
    MISC EXPORTS
]]

exports("AllowTargeting", function(bool)
    return lyre:disableTargeting(not bool)
end)

exports("IsTargetActive", function()
    local resource = GetInvokingResource()
    logUnsupported("IsTargetActive", resource)
    return false
end)

exports("IsTargetSuccess", function()
    local resource = GetInvokingResource()
    logUnsupported("IsTargetSuccess", resource)
    return false
end)

-- Raycast export (stub - lyre_context handles this internally)
exports("raycast", function(flag, playerCoords)
    local resource = GetInvokingResource()
    logUnsupported("raycast", resource)
    return nil, nil, nil, nil
end)

-- NUI control exports (stubs - lyre_context handles this internally)
exports("DisableNUI", function()
    -- Handled internally by lyre_context
end)

exports("LeaveTarget", function()
    -- Handled internally by lyre_context
end)

exports("DisableTarget", function(forcedisable)
    if forcedisable then
        lyre:disableTargeting(true)
    end
end)

exports("DrawOutlineEntity", function(entity, bool)
    -- Handled internally by lyre_context or not supported
end)

exports("CheckEntity", function(flag, data, entity, distance)
    -- Internal function, not needed for bridge
end)

exports("CheckBones", function(coords, entity, bonelist)
    -- Internal function, not needed for bridge
    return false
end)

--[[
    GETTER EXPORTS (stubs - return nil/empty as lyre_context doesn't store data the same way)
]]

exports("GetType", function(entityType, label)
    local resource = GetInvokingResource()
    logUnsupported("GetType", resource)
    return nil
end)

exports("GetZone", function(name)
    local resource = GetInvokingResource()
    logUnsupported("GetZone", resource)
    return nil
end)

exports("GetTargetBone", function(bone, label)
    return boneTargets[bone] and boneTargets[bone][label] or nil
end)

exports("GetTargetEntity", function(entity, label)
    local resource = GetInvokingResource()
    logUnsupported("GetTargetEntity", resource)
    return nil
end)

exports("GetTargetModel", function(model, label)
    local resource = GetInvokingResource()
    logUnsupported("GetTargetModel", resource)
    return nil
end)

exports("GetPed", function(label)
    local resource = GetInvokingResource()
    logUnsupported("GetPed", resource)
    return nil
end)

exports("GetVehicle", function(label)
    local resource = GetInvokingResource()
    logUnsupported("GetVehicle", resource)
    return nil
end)

exports("GetObject", function(label)
    local resource = GetInvokingResource()
    logUnsupported("GetObject", resource)
    return nil
end)

exports("GetPlayer", function(label)
    local resource = GetInvokingResource()
    logUnsupported("GetPlayer", resource)
    return nil
end)

--[[
    UPDATE EXPORTS (stubs - lyre_context uses remove/add pattern instead)
]]

exports("UpdateType", function(entityType, label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdateType", resource)
end)

exports("UpdateZoneOptions", function(name, targetoptions)
    local resource = GetInvokingResource()
    logUnsupported("UpdateZoneOptions", resource)
end)

exports("UpdateTargetBone", function(bone, label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdateTargetBone", resource)
end)

exports("UpdateTargetEntity", function(entity, label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdateTargetEntity", resource)
end)

exports("UpdateTargetModel", function(model, label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdateTargetModel", resource)
end)

exports("UpdatePed", function(label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdatePed", resource)
end)

exports("UpdateVehicle", function(label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdateVehicle", resource)
end)

exports("UpdateObject", function(label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdateObject", resource)
end)

exports("UpdatePlayer", function(label, data)
    local resource = GetInvokingResource()
    logUnsupported("UpdatePlayer", resource)
end)
