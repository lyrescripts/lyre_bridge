LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "qbx_vehiclekeys",
    resource = "qbx_vehiclekeys",
    priority = 10,
    isAvailable = function(self, context)
        return LyreBridge.isStarted(self.resource)
            and context.vehicle
            and context.vehicle ~= 0
            and lib
            and lib.callback
    end,
    give = function(self, context)
        lib.callback.await("qbx_vehiclekeys:server:giveKeys", false, VehToNet(context.vehicle))
        return true
    end,
})
