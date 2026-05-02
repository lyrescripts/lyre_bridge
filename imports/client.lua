if not LyreBridge or not LyreBridge.setupBridge then
    local runtime = LoadResourceFile("lyre_bridge", "imports/shared.lua")
    assert(runtime, "lyre_bridge imports/shared.lua is missing")

    local fn, err = load(runtime, "@lyre_bridge/imports/shared.lua")
    assert(fn, err)
    fn()
end

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

function Core.setupClientResourceBridge(config, options)
    options = options or {}
    config = config or _G.Config or {}

    local resourceName = options.resource or currentResourceName()
    Core._clientBridgeSetup = Core._clientBridgeSetup or {}

    if Core._clientBridgeSetup[resourceName] then
        return true, _G.bridge
    end

    Core._clientBridgeSetup[resourceName] = true

    local setupOptions = {}
    for key, value in pairs(options) do
        setupOptions[key] = value
    end

    setupOptions.resource = resourceName
    setupOptions.required = getRequiredFunctions(config, options)

    local success, result = Core.setupBridge("client", _G.bridge, config, setupOptions)
    if not success then
        Core._clientBridgeSetup[resourceName] = nil
        Core.log("error", result and result.message or "Unable to setup the client bridge.", {
            resource = resourceName,
            side = "client",
        })
        return false, result
    end

    return true, result
end

Core.registerModule("client", "notifications", function()
    local module = {}

    local function frameworkNotify(bridge, message, notificationType, duration)
        if type(bridge) == "table" and type(bridge.object) == "table" then
            if type(bridge.object.ShowNotification) == "function" then
                bridge.object.ShowNotification(message)
                return true
            end

            if bridge.object.Functions and type(bridge.object.Functions.Notify) == "function" then
                bridge.object.Functions.Notify(message, notificationType or "success", duration or 5000)
                return true
            end
        end

        if Core.isStarted("es_extended") then
            local ok = pcall(function()
                local esx = exports["es_extended"]:getSharedObject()
                if esx and type(esx.ShowNotification) == "function" then
                    esx.ShowNotification(message)
                else
                    error("esx_notification_missing")
                end
            end)
            if ok then
                return true
            end
        end

        if Core.isStarted("qb-core") then
            local ok = pcall(function()
                local qb = exports["qb-core"]:GetCoreObject()
                qb.Functions.Notify(message, notificationType or "success", duration or 5000)
            end)
            if ok then
                return true
            end
        end

        return false
    end

    function module.show(message, notificationType, duration, bridge)
        message = tostring(message or "")
        notificationType = notificationType or "inform"

        if Core.isStarted("ox_lib") and lib and type(lib.notify) == "function" then
            lib.notify({
                description = message,
                type = notificationType,
                duration = duration or 5000,
            })
            return true
        end

        if frameworkNotify(bridge, message, notificationType, duration) then
            return true
        end

        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
        return true
    end

    function module.help(message, bridge)
        message = tostring(message or "")

        if type(bridge) == "table"
            and type(bridge.object) == "table"
            and type(bridge.object.ShowHelpNotification) == "function"
        then
            bridge.object.ShowHelpNotification(message)
            return true
        end

        SetTextComponentFormat("STRING")
        AddTextComponentString(message)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        return true
    end

    return module
end)

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

Core.registerModule("client", "vehicleKeys", function()
    local module = {}

    local function resolveKeyRequest(plateOrNetId, netId, options)
        options = options or {}

        local vehicle = options.vehicle
        local plate = type(plateOrNetId) == "string" and plateOrNetId or options.plate

        if not vehicle then
            if type(plateOrNetId) == "number" and netId == nil then
                vehicle = resolveVehicle(plateOrNetId, options.timeoutMs)
                netId = plateOrNetId
            elseif type(netId) == "number" then
                vehicle = resolveVehicle(netId, options.timeoutMs)
            end
        end

        if (not plate or plate == "") and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            plate = GetVehicleNumberPlateText(vehicle)
        end

        local model = nil
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        end

        return plate, netId, vehicle, model
    end

    function module.give(plateOrNetId, netId, options)
        options = options or {}

        local plate, resolvedNetId, vehicle, model = resolveKeyRequest(plateOrNetId, netId, options)
        if not plate or plate == "" then
            return false, Core.fail("vehicle_plate_missing", "Unable to give vehicle keys without a plate.", {
                resource = currentResourceName(),
            })
        end

        local providers = {
            function()
                if Core.isStarted("vehicles_keys") then
                    TriggerServerEvent("vehicles_keys:selfGiveVehicleKeys", plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("fivecode_carkeys") then
                    if vehicle and vehicle ~= 0 then
                        local ok = pcall(function()
                            exports["fivecode_carkeys"]:GiveKey(vehicle, false, true)
                        end)
                        if ok then
                            return true
                        end
                    end

                    TriggerServerEvent("fivecode_carkeys:pdmGiveKey", plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("stasiek_vehiclekeys") and vehicle and vehicle ~= 0 then
                    DecorSetInt(vehicle, "owner", GetPlayerServerId(PlayerId()))
                    return true
                end
            end,
            function()
                if Core.isStarted("ti_vehicleKeys") then
                    exports["ti_vehicleKeys"]:addTemporaryVehicle(plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("F_RealCarKeysSystem") then
                    TriggerServerEvent("F_RealCarKeysSystem:generateVehicleKeys", plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("qb-vehiclekeys") then
                    TriggerEvent("vehiclekeys:client:SetOwner", plate)
                    TriggerEvent("vehiclekeys:client:AddKeys", plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("ak47_qb_vehiclekeys") then
                    exports["ak47_qb_vehiclekeys"]:GiveKey(plate, false)
                    return true
                end
            end,
            function()
                if Core.isStarted("ak47_vehiclekeys") then
                    exports["ak47_vehiclekeys"]:GiveKey(plate, false)
                    return true
                end
            end,
            function()
                if Core.isStarted("mk_vehiclekeys") and vehicle and vehicle ~= 0 then
                    exports["mk_vehiclekeys"]:AddKey(vehicle)
                    return true
                end
            end,
            function()
                if Core.isStarted("MrNewbVehicleKeys") then
                    exports["MrNewbVehicleKeys"]:GiveKeysByPlate(plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("qbx_vehiclekeys") and vehicle and vehicle ~= 0 and lib and lib.callback then
                    lib.callback.await("qbx_vehiclekeys:server:giveKeys", false, VehToNet(vehicle))
                    return true
                end
            end,
            function()
                if Core.isStarted("qs-vehiclekeys") then
                    exports["qs-vehiclekeys"]:GiveKeys(plate, model, true)
                    return true
                end
            end,
            function()
                if Core.isStarted("t1ger_keys") then
                    exports["t1ger_keys"]:GiveTemporaryKeys(plate, model, options.keyType or "temporary")
                    return true
                end
            end,
            function()
                if Core.isStarted("tgiann-hotwire") then
                    exports["tgiann-hotwire"]:GiveKeyPlate(plate, true)
                    return true
                end
            end,
            function()
                if Core.isStarted("wasabi_carlock") then
                    exports["wasabi_carlock"]:GiveKey(plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("xd_locksystem") then
                    local ok = pcall(function()
                        exports["xd_locksystem"]:SetVehicleKey(plate)
                    end)
                    if ok then
                        return true
                    end

                    exports["xd_locksystem"]:givePlayerKeys(plate)
                    return true
                end
            end,
            function()
                if Core.isStarted("Renewed-Vehiclekeys") then
                    exports["Renewed-Vehiclekeys"]:addKey(plate)
                    return true
                end
            end,
        }

        for _, provider in ipairs(providers) do
            local ok, handled = pcall(provider)
            if ok and handled then
                return true
            end
        end

        return false, Core.fail("vehicle_keys_provider_missing", "No supported vehicle key resource handled the key request.", {
            resource = currentResourceName(),
            plate = plate,
            netId = resolvedNetId,
        })
    end

    function module.remove()
        return true
    end

    return module
end)

Core.registerModule("client", "fuel", function()
    local module = {}

    local setProviders = {
        { resource = "lyre_fuel", export = "SetFuel" },
        { resource = "LegacyFuel", export = "SetFuel" },
        { resource = "esx-sna-fuel", export = "SetFuel" },
        { resource = "ps-fuel", export = "SetFuel" },
        { resource = "lj-fuel", export = "SetFuel" },
        { resource = "BigDaddy-Fuel", export = "SetFuel" },
        { resource = "cdn-fuel", export = "SetFuel" },
        { resource = "lc_fuel", export = "SetFuel" },
        { resource = "myFuel", export = "SetFuel" },
        { resource = "okokGasStation", export = "SetFuel" },
        { resource = "qb-fuel", export = "SetFuel" },
        { resource = "qb-sna-fuel", export = "SetFuel" },
        { resource = "Renewed-Fuel", export = "SetFuel" },
        { resource = "x-fuel", export = "SetFuel" },
    }

    function module.set(vehicleOrNetId, fuel)
        local vehicle = resolveVehicle(vehicleOrNetId, 2500)
        fuel = (tonumber(fuel) or 0.0) + 0.0

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            return false, Core.fail("invalid_vehicle", "Unable to set fuel because the vehicle does not exist.", {
                resource = currentResourceName(),
            })
        end

        for _, provider in ipairs(setProviders) do
            if Core.isStarted(provider.resource) then
                local ok = pcall(function()
                    exports[provider.resource][provider.export](vehicle, fuel)
                end)
                if ok then
                    return true
                end
            end
        end

        if Core.isStarted("ox_fuel") then
            Entity(vehicle).state.fuel = fuel
            return true
        end

        if Core.isStarted("ti_fuel") then
            local ok = pcall(function()
                exports["ti_fuel"]:setFuel(vehicle, fuel, "RON91")
            end)
            if ok then
                return true
            end
        end

        if Core.isStarted("ND_Fuel") then
            SetVehicleFuelLevel(vehicle, fuel)
            DecorSetFloat(vehicle, "_ANDY_FUEL_DECORE_", fuel)
            return true
        end

        if Core.isStarted("rcore_fuel") then
            local ok = pcall(function()
                exports["rcore_fuel"]:SetVehicleFuel(vehicle, fuel)
            end)
            if ok then
                return true
            end
        end

        SetVehicleFuelLevel(vehicle, fuel)
        return true
    end

    function module.get(vehicleOrNetId)
        local vehicle = resolveVehicle(vehicleOrNetId, 2500)

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            return 100.0
        end

        if Core.isStarted("ox_fuel") then
            local stateFuel = Entity(vehicle).state.fuel
            if stateFuel ~= nil then
                return stateFuel + 0.0
            end
        end

        return (GetVehicleFuelLevel(vehicle) or 100.0) + 0.0
    end

    return module
end)

Core.registerModule("client", "progress", function()
    local module = {}

    local function normalizeProgress(first, second, third)
        if type(first) == "table" then
            return first
        end

        local extra = type(third) == "table" and third or {}
        return {
            duration = tonumber(first) or extra.duration or 0,
            label = second or extra.label or extra.text,
            useWhileDead = extra.useWhileDead or false,
            canCancel = extra.canCancel or false,
            disable = extra.disable or {
                move = extra.disableMove ~= false,
                car = extra.disableCar ~= false,
                combat = extra.disableCombat ~= false,
            },
            anim = extra.anim,
            prop = extra.prop,
        }
    end

    function module.run(first, second, third)
        local options = normalizeProgress(first, second, third)

        if Core.isStarted("ox_lib") and lib then
            if type(lib.progressCircle) == "function" then
                return lib.progressCircle(options)
            end

            if type(lib.progressBar) == "function" then
                return lib.progressBar(options)
            end
        end

        if options.duration and options.duration > 0 then
            Wait(options.duration)
        end

        return true
    end

    return module
end)
