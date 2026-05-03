LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "ak47_vehiclekeys",
    resource = "ak47_vehiclekeys",
    priority = 80,
    give = function(self, context)
        exports["ak47_vehiclekeys"]:GiveKey(context.plate, false)
        return true
    end,
})
