local provider = LyreBridge.registerProvider("server", "inventory", "qb", 50)

---Active when `qb-core` is the only inventory source running.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Add `count` units of `itemName` to the player's inventory.
---@param source integer
---@param itemName string
---@param count integer Positive integer; 1 when nil.
---@param metadata? table Per-item metadata forwarded to QBCore.
---@return boolean
function provider:addItem(source, itemName, count, metadata)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    return qbPlayer.Functions.AddItem(itemName, count or 1, nil, metadata)
end

---Remove `count` units of `itemName` from the player's inventory.
---@param source integer
---@param itemName string
---@param count integer Positive integer; 1 when nil.
---@param slot? integer When provided, removes from that specific slot.
---@return boolean
function provider:removeItem(source, itemName, count, slot)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    return qbPlayer.Functions.RemoveItem(itemName, count or 1, slot)
end

---Return the total quantity of `itemName` carried by the player.
---@param source integer
---@param itemName string
---@return integer
function provider:getItemCount(source, itemName)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return 0 end
    local item = qbPlayer.Functions.GetItemByName(itemName)
    return item and item.amount or 0
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
    return true
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
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    qbPlayer.Functions.SetInventory(qbPlayer.PlayerData.items)
    return true
end

---Return the item currently held in `slot`.
---@param source integer
---@param slot integer
---@return table?
function provider:getItemBySlot(source, slot)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return nil end
    return qbPlayer.PlayerData.items and qbPlayer.PlayerData.items[slot]
end

---Whether per-item metadata survives across saves.
---@return boolean
function provider:supportsMetadata()
    return true
end
