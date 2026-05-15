local provider = LyreBridge.registerProvider("server", "inventory", "qs_inventory", 20)

---Active when `qs-inventory` is running and ox_inventory is not.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qs-inventory")
    and not bridge.core.isStarted("ox_inventory")
end

---Add `count` units of `itemName` to the player's inventory.
---@param source integer
---@param itemName string
---@param count integer Positive integer; 1 when nil.
---@param metadata? table Per-slot metadata forwarded to qs-inventory.
---@return boolean
function provider:addItem(source, itemName, count, metadata)
    return exports["qs-inventory"]:AddItem(source, itemName, count or 1, nil, metadata) ~= false
end

---Remove `count` units of `itemName` from the player's inventory.
---@param source integer
---@param itemName string
---@param count integer Positive integer; 1 when nil.
---@param slot? integer When provided, removes from that specific slot.
---@return boolean
function provider:removeItem(source, itemName, count, slot)
    return exports["qs-inventory"]:RemoveItem(source, itemName, count or 1, slot) ~= false
end

---Return the total quantity of `itemName` carried by the player.
---@param source integer
---@param itemName string
---@return integer
function provider:getItemCount(source, itemName)
    return exports["qs-inventory"]:GetItemTotalAmount(source, itemName) or 0
end

---Whether the player carries at least `count` of `itemName` (default 1).
---@param source integer
---@param itemName string
---@param count? integer
---@return boolean
function provider:hasItem(source, itemName, count)
    return self:getItemCount(source, itemName) >= (count or 1)
end

---Whether the player has weight/slot space for `count` units of `itemName`.
---@param source integer
---@param itemName string
---@param count integer
---@return boolean
function provider:canCarryItem(source, itemName, count)
    return exports["qs-inventory"]:CanCarryItem(source, itemName, count or 1) ~= false
end

---Top up the player's ammo for a given weapon.
---@param source integer
---@param ammoItem string Inventory item representing the ammo to grant.
---@param weapon string
---@param amount integer
---@return boolean
function provider:addAmmo(source, ammoItem, weapon, amount)
    return self:addItem(source, ammoItem, amount)
end

---Replace metadata on an item slot.
---@param source integer
---@param itemName string
---@param slot integer
---@param metadata table
---@return boolean
function provider:setItemMetadata(source, itemName, slot, metadata)
    exports["qs-inventory"]:SetItemMetadata(source, slot, metadata)
    return true
end

---Return the item currently held in `slot`.
---@param source integer
---@param slot integer
---@return table?
function provider:getItemBySlot(source, slot)
    return exports["qs-inventory"]:GetItemBySlot(source, slot)
end

---Whether per-item metadata survives across saves.
---@return boolean
function provider:supportsMetadata()
    return true
end
