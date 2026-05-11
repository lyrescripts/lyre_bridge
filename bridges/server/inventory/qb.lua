local provider = LyreBridge.registerProvider("server", "inventory", "qb", 50)

function provider:detect()
    return bridge.core:isStarted("qb-core")
    and not bridge.core:isStarted("ox_inventory")
    and not bridge.core:isStarted("qs-inventory")
end

function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

function provider:addItem(source, itemName, count, metadata)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    return qbPlayer.Functions.AddItem(itemName, count or 1, nil, metadata)
end

function provider:removeItem(source, itemName, count, slot)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    return qbPlayer.Functions.RemoveItem(itemName, count or 1, slot)
end

function provider:getItemCount(source, itemName)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return 0 end
    local item = qbPlayer.Functions.GetItemByName(itemName)
    return item and item.amount or 0
end

function provider:hasItem(source, itemName, count)
    return self:getItemCount(source, itemName) >= (count or 1)
end

function provider:canCarryItem(source, itemName, count)
    return true
end

function provider:addAmmo(source, ammoItem, weapon, amount)
    return self:addItem(source, ammoItem, amount)
end

function provider:setItemMetadata(source, itemName, slot, metadata)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    qbPlayer.Functions.SetInventory(qbPlayer.PlayerData.items)
    return true
end

function provider:getItemBySlot(source, slot)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return nil end
    return qbPlayer.PlayerData.items and qbPlayer.PlayerData.items[slot]
end

function provider:supportsMetadata()
    return true
end
