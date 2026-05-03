LyreBridge.registerProvider("server", "inventory", {
    name = "qs-inventory",
    resource = "qs-inventory",
    priority = 20,
    isAvailable = function(self, context)
        return LyreBridge.isStarted(self.resource) and context.raw ~= nil
    end,
    addItem = function(self, context)
        if context.raw.Functions and type(context.raw.Functions.AddItem) == "function" then
            context.raw.Functions.AddItem(context.itemName, context.count, nil, context.metadata)
            return true, true
        end

        if type(context.raw.addInventoryItem) ~= "function" then
            return false
        end

        context.raw.addInventoryItem(context.itemName, context.count, context.metadata)
        return true, true
    end,
    addAmmo = function(self, context)
        if context.raw.Functions and type(context.raw.Functions.AddItem) == "function" then
            context.raw.Functions.AddItem(context.ammoItem or context.itemName, context.count)
            return true, true
        end

        if type(context.raw.addInventoryItem) ~= "function" then
            return false
        end

        context.raw.addInventoryItem(context.ammoItem or context.itemName, context.count)
        return true, true
    end,
    removeItem = function(self, context)
        if context.raw.Functions and type(context.raw.Functions.RemoveItem) == "function" then
            context.raw.Functions.RemoveItem(context.itemName, context.count, context.slot)
            return true, true
        end

        if type(context.raw.removeInventoryItem) ~= "function" then
            return false
        end

        context.raw.removeInventoryItem(context.itemName, context.count)
        return true, true
    end,
    getItemCount = function(self, context)
        if context.raw.Functions and type(context.raw.Functions.GetItemByName) == "function" then
            local item = context.raw.Functions.GetItemByName(context.itemName)
            return true, item and (item.amount or item.count) or 0
        end

        if type(context.raw.getInventoryItem) ~= "function" then
            return false
        end

        local item = context.raw.getInventoryItem(context.itemName)
        return true, item and (item.count or item.amount) or 0
    end,
    canCarryItem = function(self, context)
        if context.raw.Functions and type(context.raw.Functions.CanCarryItem) == "function" then
            return true, context.raw.Functions.CanCarryItem(context.itemName, context.count)
        end

        if type(context.raw.canCarryItem) == "function" then
            return true, context.raw.canCarryItem(context.itemName, context.count)
        end

        return true, true
    end,
})
