LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "ak47_qb_vehiclekeys",
    resource = "ak47_qb_vehiclekeys",
    priority = 70,
    give = function(self, context)
        exports["ak47_qb_vehiclekeys"]:GiveKey(context.plate, false)
        return true
    end,
})
