LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "qb-vehiclekeys",
    resource = "qb-vehiclekeys",
    priority = 20,
    give = function(self, context)
        TriggerEvent("vehiclekeys:client:SetOwner", context.plate)
        TriggerEvent("vehiclekeys:client:AddKeys", context.plate)
        return true
    end,
})
