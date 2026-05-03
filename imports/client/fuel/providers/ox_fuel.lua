LyreBridge.registerProvider("client", "fuel", {
    name = "ox_fuel",
    resource = "ox_fuel",
    priority = 60,
    set = function(self, context, vehicle, fuel)
        Entity(vehicle).state.fuel = fuel
        return true
    end,
    get = function(self, context, vehicle)
        local fuel = Entity(vehicle).state.fuel
        if fuel ~= nil then
            return true, fuel
        end
    end,
})
