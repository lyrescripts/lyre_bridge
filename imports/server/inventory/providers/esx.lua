LyreBridge.registerProvider("server", "inventory", {
    name = "esx",
    priority = 100,
    isAvailable = function(self, context)
        return context.framework == "ESX" and context.raw ~= nil
    end,
    addItem = function(self, context)
        if type(context.raw.addInventoryItem) ~= "function" then
            return false
        end

        context.raw.addInventoryItem(context.itemName, context.count, context.metadata)
        return true, true
    end,
    removeItem = function(self, context)
        if type(context.raw.removeInventoryItem) ~= "function" then
            return false
        end

        context.raw.removeInventoryItem(context.itemName, context.count)
        return true, true
    end,
    getItemCount = function(self, context)
        if type(context.raw.getInventoryItem) ~= "function" then
            return false
        end

        local item = context.raw.getInventoryItem(context.itemName)
        return true, item and (item.count or item.amount) or 0
    end,
})
