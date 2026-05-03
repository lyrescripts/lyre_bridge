LyreBridge.registerProvider("server", "inventory", {
    name = "esx",
    priority = 100,
    isAvailable = function(self, context)
        return context.framework == "ESX" and context.raw ~= nil
    end,
    addItem = function(self, context)
        if type(context.itemName) ~= "string" or context.itemName == "" then
            return false
        end

        if context.itemName:sub(1, 7) == "weapon_" and type(context.raw.addWeapon) == "function" then
            context.raw.addWeapon(context.itemName, tonumber(context.ammo) or 100)
            return true, true
        end

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
    canCarryItem = function(self, context)
        if type(context.raw.canCarryItem) ~= "function" then
            return true, true
        end

        return true, context.raw.canCarryItem(context.itemName, context.count)
    end,
    addAmmo = function(self, context)
        if type(context.weaponName) == "string" and context.weaponName ~= "" and type(context.raw.addWeaponAmmo) == "function" then
            context.raw.addWeaponAmmo(context.weaponName, context.count)
            return true, true
        end

        if type(context.raw.addInventoryItem) ~= "function" then
            return false
        end

        context.raw.addInventoryItem(context.ammoItem or context.itemName, context.count)
        return true, true
    end,
})
