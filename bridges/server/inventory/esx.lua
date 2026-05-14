local provider = LyreBridge.registerProvider("server", "inventory", "esx", 70)

function provider:detect()
    return bridge.core.isStarted("es_extended")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

function provider:addItem(source, itemName, count, metadata)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    xPlayer.addInventoryItem(itemName, count or 1, metadata)
    return true
end

function provider:removeItem(source, itemName, count, slot)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    xPlayer.removeInventoryItem(itemName, count or 1)
    return true
end

function provider:getItemCount(source, itemName)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    local item = xPlayer.getInventoryItem(itemName)
    return item and item.count or 0
end

function provider:hasItem(source, itemName, count)
    return self:getItemCount(source, itemName) >= (count or 1)
end

function provider:canCarryItem(source, itemName, count)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    local item = xPlayer.getInventoryItem(itemName)
    if not item then return false end
    return (xPlayer.getMaxWeight() - xPlayer.getWeight()) >= (item.weight or 0) * (count or 1)
end

function provider:addAmmo(source, ammoItem, weapon, amount)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    xPlayer.addWeaponAmmo(weapon, amount or 1)
    return true
end

function provider:setItemMetadata(source, itemName, slot, metadata)
    return false
end

function provider:getItemBySlot(source, slot)
    return nil
end

function provider:supportsMetadata()
    return false
end
