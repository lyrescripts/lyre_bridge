local Core = LyreBridge
local internals = Core._clientInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName
local resolveVehicle = internals.resolveVehicle
Core.registerModule("client", "fuel", function()
    local module = {}

    local function callProvider(methodName, context, ...)
        for _, provider in ipairs(Core.getProviders("client", "fuel")) do
            if type(provider[methodName]) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled, result = pcall(provider[methodName], provider, context, ...)
                if ok and handled then
                    Core.log("debug", "Fuel provider handled request.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        method = methodName,
                    })
                    return true, result
                end

                if not ok then
                    Core.log("warn", "Fuel provider failed.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        method = methodName,
                        error = tostring(handled),
                    })
                end
            end
        end

        return false
    end

    function module.set(vehicleOrNetId, fuel)
        local vehicle = resolveVehicle(vehicleOrNetId, 2500)
        fuel = (tonumber(fuel) or 0.0) + 0.0

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            return false, Core.fail("invalid_vehicle", "Unable to set fuel because the vehicle does not exist.", {
                resource = currentResourceName(),
            })
        end

        local handled = callProvider("set", {
            resource = currentResourceName(),
            vehicle = vehicle,
            fuel = fuel,
        }, vehicle, fuel)

        if handled then
            return true
        end

        SetVehicleFuelLevel(vehicle, fuel)
        return true
    end

    function module.get(vehicleOrNetId)
        local vehicle = resolveVehicle(vehicleOrNetId, 2500)

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            return 100.0
        end

        local handled, fuel = callProvider("get", {
            resource = currentResourceName(),
            vehicle = vehicle,
        }, vehicle)

        if handled and fuel ~= nil then
            return (tonumber(fuel) or 100.0) + 0.0
        end

        return (GetVehicleFuelLevel(vehicle) or 100.0) + 0.0
    end

    return module
end)
