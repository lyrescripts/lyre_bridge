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

        local context = {
            resource = currentResourceName(),
            plate = plate,
            netId = resolvedNetId,
            vehicle = vehicle,
            model = model,
            options = options,
        }

        for _, provider in ipairs(Core.getProviders("client", "vehicleKeys")) do
            if type(provider.give) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled = pcall(provider.give, provider, context)
                if ok and handled then
                    Core.log("debug", "Vehicle key provider handled request.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        method = "give",
                    })
                    return true
                end

                if not ok then
                    Core.log("warn", "Vehicle key provider failed.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        error = tostring(handled),
                    })
                end
            end
        end

        for _, provider in ipairs(Core.getProviders("client", "vehicleKeys")) do
            if type(provider.giveWithoutResourceCheck) == "function" then
                local ok, handled = pcall(provider.giveWithoutResourceCheck, provider, context)
                if ok and handled then
                    Core.log("debug", "Vehicle key fallback provider handled request.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        method = "give",
                    })
                    return true
                end

                if not ok then
                    Core.log("warn", "Vehicle key fallback provider failed.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        error = tostring(handled),
                    })
                end
            end
        end

        return false, Core.fail("vehicle_keys_provider_missing", "No supported vehicle key resource handled the key request.", {
            resource = currentResourceName(),
            plate = plate,
            netId = resolvedNetId,
        })
    end

    function module.remove(plate, options)
        local context = {
            resource = currentResourceName(),
            plate = plate,
            options = options or {},
        }

        for _, provider in ipairs(Core.getProviders("client", "vehicleKeys")) do
            if type(provider.remove) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled = pcall(provider.remove, provider, context)
                if ok and handled then
                    Core.log("debug", "Vehicle key provider handled request.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        method = "remove",
                    })
                    return true
                end

                if not ok then
                    Core.log("warn", "Vehicle key remove provider failed.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        error = tostring(handled),
                    })
                end
            end
        end

        return true
    end

    return module
end)
