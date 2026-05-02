local Core = LyreBridge
local internals = Core._clientInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName
local pcallExport = internals.pcallExport
local toArray = internals.toArray
Core.registerModule("client", "target", function()
    local module = {}
    local localEntityTargets = {}
    local generatedZoneIndex = 0

    local function nextZoneName()
        generatedZoneIndex = generatedZoneIndex + 1
        return ("%s_zone_%d"):format(currentResourceName(), generatedZoneIndex)
    end

    local function optionNames(option)
        local names = {}

        if type(option) ~= "table" then
            return names
        end

        if option.name then
            names[#names + 1] = option.name
        end

        if option.label and option.label ~= option.name then
            names[#names + 1] = option.label
        end

        return names
    end

    local function rememberLocalEntity(entity, options)
        for _, option in ipairs(options) do
            local names = optionNames(option)

            for _, name in ipairs(names) do
                localEntityTargets[name] = localEntityTargets[name] or { entity = entity, names = {} }
                localEntityTargets[name].entity = entity

                for _, trackedName in ipairs(names) do
                    local exists = false
                    for _, existingName in ipairs(localEntityTargets[name].names) do
                        if existingName == trackedName then
                            exists = true
                            break
                        end
                    end

                    if not exists then
                        localEntityTargets[name].names[#localEntityTargets[name].names + 1] = trackedName
                    end
                end
            end
        end
    end

    local function normalizeOptions(options)
        local normalized = toArray(options)

        for _, option in ipairs(normalized) do
            if type(option) == "table" and not option.name and option.label then
                option.name = option.label
            end
        end

        return normalized
    end

    local function targetDistance(options, defaultDistance)
        for _, option in ipairs(options or {}) do
            if type(option) == "table" and tonumber(option.distance) then
                return tonumber(option.distance)
            end
        end

        return defaultDistance or 2.5
    end

    local function asQbOptions(options)
        local qbOptions = {}

        for index, option in ipairs(options) do
            qbOptions[index] = {
                label = option.label,
                icon = option.icon,
                event = option.event,
                type = option.type,
                item = option.item,
                job = option.job,
                gang = option.gang,
                canInteract = option.canInteract,
            }

            if option.serverEvent and not option.event then
                qbOptions[index].event = option.serverEvent
                qbOptions[index].type = "server"
            end

            if option.action then
                qbOptions[index].action = option.action
            elseif option.onSelect then
                qbOptions[index].action = function(entity)
                    return option.onSelect({ entity = entity })
                end
            end
        end

        return qbOptions
    end

    local function pcallTarget(resourceName, exportName, ...)
        local ok, result = pcallExport(resourceName, exportName, ...)
        if ok then
            return true, result
        end

        return false, result
    end

    function module.addLocalEntity(entity, options)
        local normalizedOptions = normalizeOptions(options)
        if #normalizedOptions == 0 then
            return false, Core.fail("target_options_missing", "No target options were provided.", {
                resource = currentResourceName(),
                side = "client",
            })
        end

        rememberLocalEntity(entity, normalizedOptions)

        if Core.isStarted("ox_target") then
            local ok, err = pcall(function()
                exports["ox_target"]:addLocalEntity(entity, normalizedOptions)
            end)
            if ok then
                return true
            end
            return false, err
        end

        if Core.isStarted("qb-target") then
            return pcallTarget("qb-target", "AddTargetEntity", entity, {
                options = asQbOptions(normalizedOptions),
                distance = targetDistance(normalizedOptions, 2.5),
            })
        end

        if Core.isStarted("qtarget") then
            return pcallTarget("qtarget", "AddTargetEntity", entity, {
                options = asQbOptions(normalizedOptions),
                distance = targetDistance(normalizedOptions, 2.5),
            })
        end

        return false, Core.fail("target_missing", "No supported target resource is started.", {
            resource = currentResourceName(),
            side = "client",
        })
    end

    local function resolveTrackedEntity(entityOrName, optionNamesOverride)
        if type(entityOrName) ~= "string" then
            return entityOrName, optionNamesOverride
        end

        local tracked = localEntityTargets[entityOrName]
        if not tracked then
            return entityOrName, optionNamesOverride
        end

        return tracked.entity, optionNamesOverride or tracked.names
    end

    local function forgetTrackedEntity(entity, names)
        if type(names) == "table" then
            for _, name in ipairs(names) do
                localEntityTargets[name] = nil
            end
            return
        end

        for name, tracked in pairs(localEntityTargets) do
            if tracked.entity == entity then
                localEntityTargets[name] = nil
            end
        end
    end

    function module.removeEntity(entityOrName, optionNamesOverride)
        local entity, names = resolveTrackedEntity(entityOrName, optionNamesOverride)

        if Core.isStarted("ox_target") then
            local ok = pcall(function()
                exports["ox_target"]:removeLocalEntity(entity, names)
            end)
            if ok then
                forgetTrackedEntity(entity, names)
                return true
            end

            local fallbackOk, fallbackResult = pcallTarget("ox_target", "removeLocalEntity", entity)
            if fallbackOk then
                forgetTrackedEntity(entity, names)
            end
            return fallbackOk, fallbackResult
        end

        if Core.isStarted("qb-target") then
            local ok = pcall(function()
                exports["qb-target"]:RemoveTargetEntity(entity, names)
            end)
            if ok then
                forgetTrackedEntity(entity, names)
                return true
            end

            local fallbackOk, fallbackResult = pcallTarget("qb-target", "RemoveTargetEntity", entity)
            if fallbackOk then
                forgetTrackedEntity(entity, names)
            end
            return fallbackOk, fallbackResult
        end

        if Core.isStarted("qtarget") then
            local ok = pcall(function()
                exports["qtarget"]:RemoveTargetEntity(entity, names)
            end)
            if ok then
                forgetTrackedEntity(entity, names)
                return true
            end

            local fallbackOk, fallbackResult = pcallTarget("qtarget", "RemoveTargetEntity", entity)
            if fallbackOk then
                forgetTrackedEntity(entity, names)
            end
            return fallbackOk, fallbackResult
        end

        forgetTrackedEntity(entity, names)
        return true
    end

    function module.addSphereZone(nameOrOptions, coords, radius, targetOptions)
        local zone

        if type(nameOrOptions) == "table" then
            zone = nameOrOptions
        else
            targetOptions = targetOptions or {}
            zone = {
                name = nameOrOptions,
                coords = coords,
                radius = radius,
                debug = targetOptions.debug,
                distance = targetOptions.distance,
                options = targetOptions.options or targetOptions,
            }
        end

        zone.name = zone.name or nextZoneName()
        zone.options = normalizeOptions(zone.options)
        if #zone.options == 0 then
            return false, Core.fail("target_options_missing", "No target options were provided.", {
                resource = currentResourceName(),
                side = "client",
            })
        end

        zone.radius = tonumber(zone.radius) or 2.0

        if Core.isStarted("ox_target") then
            local ok, result = pcall(function()
                return exports["ox_target"]:addSphereZone(zone)
            end)
            if ok then
                return result or zone.name
            end
            return false, result
        end

        local targetPayload = {
            options = asQbOptions(zone.options),
            distance = zone.distance or targetDistance(zone.options, 2.5),
        }

        if Core.isStarted("qb-target") then
            local ok, result = pcallTarget("qb-target", "AddCircleZone", zone.name, zone.coords, zone.radius, {
                name = zone.name,
                debugPoly = zone.debug or false,
            }, targetPayload)
            if ok then
                return result or zone.name
            end

            return false, result
        end

        if Core.isStarted("qtarget") then
            local ok, result = pcallTarget("qtarget", "AddCircleZone", zone.name, zone.coords, zone.radius, {
                name = zone.name,
                debugPoly = zone.debug or false,
            }, targetPayload)
            if ok then
                return result or zone.name
            end

            return false, result
        end

        return false, Core.fail("target_missing", "No supported target resource is started.", {
            resource = currentResourceName(),
            side = "client",
        })
    end

    function module.removeZone(id)
        if not id then
            return true
        end

        if Core.isStarted("ox_target") then
            return pcallTarget("ox_target", "removeZone", id)
        end

        if Core.isStarted("qb-target") then
            return pcallTarget("qb-target", "RemoveZone", id)
        end

        if Core.isStarted("qtarget") then
            return pcallTarget("qtarget", "RemoveZone", id)
        end

        return true
    end

    return module
end)
