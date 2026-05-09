LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "xd_locksystem",
    resource = "xd_locksystem",
    priority = 160,
    give = function(self, context)
        local ok = pcall(function()
            exports["xd_locksystem"]:SetVehicleKey(context.plate)
        end)
        if ok then
            return true
        end

        exports["xd_locksystem"]:givePlayerKeys(context.plate)
        return true
    end,
})
