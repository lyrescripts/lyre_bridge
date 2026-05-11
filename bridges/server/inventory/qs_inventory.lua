local provider = LyreBridge.registerProvider("server", "inventory", "qs_inventory", 20)

function provider:detect()
    return bridge.core:isStarted("qs-inventory")
    and not bridge.core:isStarted("ox_inventory")
end

function provider:addItem(source, itemName, count, metadata)
    return exports["qs-inventory"]:AddItem(source, itemName, count or 1, nil, metadata) ~= false
end

function provider:removeItem(source, itemName, count, slot)
    return exports["qs-inventory"]:RemoveItem(source, itemName, count or 1, slot) ~= false
end

function provider:getItemCount(source, itemName)
    return exports["qs-inventory"]:GetItemTotalAmount(source, itemName) or 0
end

function provider:hasItem(source, itemName, count)
    return self:getItemCount(source, itemName) >= (count or 1)
end

function provider:canCarryItem(source, itemName, count)
    return exports["qs-inventory"]:CanCarryItem(source, itemName, count or 1) ~= false
end

function provider:addAmmo(source, ammoItem, weapon, amount)
    return self:addItem(source, ammoItem, amount)
end

function provider:setItemMetadata(source, itemName, slot, metadata)
    exports["qs-inventory"]:SetItemMetadata(source, slot, metadata)
    return true
end

function provider:getItemBySlot(source, slot)
    return exports["qs-inventory"]:GetItemBySlot(source, slot)
end

function provider:supportsMetadata()
    return true
end
