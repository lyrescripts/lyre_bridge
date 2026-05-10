LyreBridge.registerProvider("server", "usableItems", {
    name = "ox_inventory",
    resource = "ox_inventory",
    priority = 300,
    isAvailable = function(self, context)
        if context.framework == "ESX" or context.framework == "QBCORE" or context.framework == "QBOX" then
            return false
        end

        return LyreBridge.isStarted(self.resource)
    end,
    register = function(self, context)
        local ok, errorMessage = pcall(function()
            exports.ox_inventory:RegisterUsableItem(context.itemName, context.callback)
        end)

        if ok then
            return true, true
        end

        -- ox_inventory uses item client/server exports in item definitions on recent versions.
        -- Lyre resources expose those item exports from their client scripts.
        if tostring(errorMessage):find("No such export RegisterUsableItem", 1, true) then
            return true, true
        end

        error(errorMessage)
    end,
})
