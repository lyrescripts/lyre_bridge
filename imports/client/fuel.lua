local Core = LyreBridge
local internals = Core._clientInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName
local resolveVehicle = internals.resolveVehicle
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
