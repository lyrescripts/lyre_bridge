LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "mk_vehiclekeys",
    resource = "mk_vehiclekeys",
    priority = 90,
    give = function(self, context)
        if not context.vehicle or context.vehicle == 0 then
            return false
        end

        exports["mk_vehiclekeys"]:AddKey(context.vehicle)
        return true
    end,
})
