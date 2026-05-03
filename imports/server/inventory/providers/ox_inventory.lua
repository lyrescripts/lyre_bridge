LyreBridge.registerProvider("server", "inventory", {
    name = "ox_inventory",
    resource = "ox_inventory",
    priority = 10,
    addItem = function(self, context)
        return true, exports.ox_inventory:AddItem(context.source, context.itemName, context.count, context.metadata) ~= false
    end,
    removeItem = function(self, context)
        return true, exports.ox_inventory:RemoveItem(context.source, context.itemName, context.count, nil, context.slot) ~= false
    end,
    getItemCount = function(self, context)
        return true, exports.ox_inventory:Search(context.source, "count", context.itemName) or 0
    end,
    getItemBySlot = function(self, context)
        if not context.slot then
            return false
        end

        return true, exports.ox_inventory:GetSlot(context.source, context.slot)
    end,
    setItemMetadata = function(self, context)
        if not context.slot then
            return false
        end

        exports.ox_inventory:SetMetadata(context.source, context.slot, context.metadata)
        return true, true
    end,
    supportsMetadata = function()
        return true, true
    end,
})
