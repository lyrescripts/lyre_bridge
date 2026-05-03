LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "stasiek_vehiclekeys",
    resource = "stasiek_vehiclekeys",
    priority = 30,
    give = function(self, context)
        if not context.vehicle or context.vehicle == 0 then
            return false
        end

        DecorSetInt(context.vehicle, "owner", GetPlayerServerId(PlayerId()))
        return true
    end,
})
