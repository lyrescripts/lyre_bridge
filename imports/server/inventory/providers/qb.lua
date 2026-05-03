LyreBridge.registerProvider("server", "inventory", {
    name = "qb",
    priority = 110,
    isAvailable = function(self, context)
        if context.framework ~= "QBCORE" and context.framework ~= "QBOX" then
            return false
        end

        if context.method == "supportsMetadata" then
            return true
        end

        return context.raw ~= nil and context.raw.Functions ~= nil
    end,
    addItem = function(self, context)
        if type(context.raw.Functions.AddItem) ~= "function" then
            return false
        end

        context.raw.Functions.AddItem(context.itemName, context.count, nil, context.metadata)
        return true, true
    end,
    removeItem = function(self, context)
        if type(context.raw.Functions.RemoveItem) ~= "function" then
            return false
        end

        context.raw.Functions.RemoveItem(context.itemName, context.count, context.slot)
        return true, true
    end,
    getItemCount = function(self, context)
        if type(context.raw.Functions.GetItemByName) ~= "function" then
            return false
        end

        local item = context.raw.Functions.GetItemByName(context.itemName)
        return true, item and (item.amount or item.count) or 0
    end,
    getItemBySlot = function(self, context)
        local items = context.raw.PlayerData and context.raw.PlayerData.items
        if not context.slot or type(items) ~= "table" then
            return false
        end

        return true, items[context.slot]
    end,
    setItemMetadata = function(self, context)
        local items = context.raw.PlayerData and context.raw.PlayerData.items
        if not items or not context.slot or not items[context.slot] then
            return false
        end

        if items[context.slot].name ~= context.itemName then
            return true, false
        end

        items[context.slot].info = context.metadata
        if type(context.raw.Functions.SetInventory) ~= "function" then
            return true, false
        end

        context.raw.Functions.SetInventory(items)
        return true, true
    end,
    supportsMetadata = function()
        return true, true
    end,
})
