local Core = LyreBridge

Core._fuelProviderHelpers = Core._fuelProviderHelpers or {}

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
    })
end

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
    })
end
