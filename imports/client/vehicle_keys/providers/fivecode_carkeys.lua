LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "fivecode_carkeys",
    resource = "fivecode_carkeys",
    priority = 80,
    give = function(self, context)
        if context.vehicle and context.vehicle ~= 0 then
            local ok = pcall(function()
                exports["fivecode_carkeys"]:GiveKey(context.vehicle, false, true)
            end)
            if ok then
                return true
            end
        end

        TriggerServerEvent("fivecode_carkeys:pdmGiveKey", context.plate)
        return true
    end,
})
