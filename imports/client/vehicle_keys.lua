local Core = LyreBridge
local internals = Core._clientInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName
local resolveVehicle = internals.resolveVehicle
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
