local provider = LyreBridge.registerProvider("server", "inventory", "ox_inventory", 10)

function provider:detect()
    return bridge.core.isStarted("ox_inventory")
end

function provider:addItem(source, itemName, count, metadata)
    return exports.ox_inventory:AddItem(source, itemName, count or 1, metadata) ~= false
end

function provider:removeItem(source, itemName, count, slot)
    return exports.ox_inventory:RemoveItem(source, itemName, count or 1, nil, slot) ~= false
end

function provider:getItemCount(source, itemName)
    return exports.ox_inventory:Search(source, "count", itemName) or 0
end

function provider:hasItem(source, itemName, count)
    return self:getItemCount(source, itemName) >= (count or 1)
end

function provider:canCarryItem(source, itemName, count)
    return exports.ox_inventory:CanCarryItem(source, itemName, count or 1) ~= false
end

function provider:addAmmo(source, ammoItem, weapon, amount)
    return exports.ox_inventory:AddItem(source, ammoItem, amount or 1) ~= false
end

function provider:setItemMetadata(source, itemName, slot, metadata)
    exports.ox_inventory:SetMetadata(source, slot, metadata)
    return true
end

function provider:getItemBySlot(source, slot)
    return exports.ox_inventory:GetSlot(source, slot)
end

function provider:supportsMetadata()
    return true
end
