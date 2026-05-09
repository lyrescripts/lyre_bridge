local Core = LyreBridge

Core._fuelProviderHelpers = Core._fuelProviderHelpers or {}

-- Provider that delegates set/get to exports[resource]:SetFuel(veh, fuel) and
-- exports[resource]:GetFuel(veh). Use for resources following the LegacyFuel
-- export contract (LegacyFuel, ps-fuel, lj-fuel, cdn-fuel, BigDaddy-Fuel,
-- qb-fuel, lc_fuel, esx-sna-fuel, qb-sna-fuel, rcore_fuel, etc.).
function Core._fuelProviderHelpers.registerSetFuelExport(resourceName, priority)
    Core.registerProvider("client", "fuel", {
        name = resourceName,
        resource = resourceName,
        priority = priority,
        set = function(self, context, vehicle, fuel)
            if not vehicle or vehicle == 0 then
                return false
            end

            local ok, result = pcall(function()
                return exports[self.resource]:SetFuel(vehicle, fuel)
            end)

            if not ok or result == false then
                return false
            end

            return true, result
        end,
        get = function(self, context, vehicle)
            if not vehicle or vehicle == 0 then
                return false
            end

            local ok, result = pcall(function()
                return exports[self.resource]:GetFuel(vehicle)
            end)

            if not ok or result == nil then
                return false
            end

            return true, result
        end,
    })
end

-- Provider that mirrors fuel via Entity(veh).state.fuel statebag. Use for
-- ox_fuel-style resources (ox_fuel, Renewed-Fuel and forks).
function Core._fuelProviderHelpers.registerStatebagFuel(resourceName, priority, key)
    key = key or "fuel"

    Core.registerProvider("client", "fuel", {
        name = resourceName,
        resource = resourceName,
        priority = priority,
        set = function(self, context, vehicle, fuel)
            if not vehicle or vehicle == 0 then
                return false
            end

            Entity(vehicle).state[key] = fuel
            return true
        end,
        get = function(self, context, vehicle)
            if not vehicle or vehicle == 0 then
                return false
            end

            local value = Entity(vehicle).state[key]
            if value == nil then
                return false
            end

            return true, value
        end,
    })
end

-- Provider that mirrors fuel via DecorGetFloat / DecorSetFloat with a custom
-- decor. Use for decor-based fuel scripts (FRFuel, ND_Fuel, LegacyFuel forks).
function Core._fuelProviderHelpers.registerDecorFuel(resourceName, priority, decorName)
    Core.registerProvider("client", "fuel", {
        name = resourceName,
        resource = resourceName,
        priority = priority,
        set = function(self, context, vehicle, fuel)
            if not vehicle or vehicle == 0 then
                return false
            end

            SetVehicleFuelLevel(vehicle, fuel)
            if type(DecorSetFloat) == "function" then
                pcall(DecorSetFloat, vehicle, decorName, fuel)
            end

            return true
        end,
        get = function(self, context, vehicle)
            if not vehicle or vehicle == 0 then
                return false
            end

            if type(DecorExistOn) == "function" and DecorExistOn(vehicle, decorName) then
                return true, DecorGetFloat(vehicle, decorName)
            end

            return false
        end,
    })
end

-- Provider that uses the GTA native fuel level only. Kept for completeness.
function Core._fuelProviderHelpers.registerNativeFuel(resourceName, priority)
    Core.registerProvider("client", "fuel", {
        name = resourceName,
        resource = resourceName,
        priority = priority,
        set = function(self, context, vehicle, fuel)
            if not vehicle or vehicle == 0 then
                return false
            end

            SetVehicleFuelLevel(vehicle, fuel)
            return true
        end,
        get = function(self, context, vehicle)
            if not vehicle or vehicle == 0 then
                return false
            end

            return true, GetVehicleFuelLevel(vehicle)
        end,
    })
end
