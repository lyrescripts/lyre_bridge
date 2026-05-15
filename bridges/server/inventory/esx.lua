local provider = LyreBridge.registerProvider("server", "inventory", "esx", 70)

---Active when `es_extended` is the only inventory source running.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Add `count` units of `itemName` to the player's inventory.
---@param source integer
---@param itemName string
---@param count integer Positive integer; 1 when nil.
---@param metadata? table Ignored by ESX inventories.
---@return boolean
function provider:addItem(source, itemName, count, metadata)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    xPlayer.addInventoryItem(itemName, count or 1, metadata)
    return true
end

---Remove `count` units of `itemName` from the player's inventory.
---@param source integer
---@param itemName string
---@param count integer Positive integer; 1 when nil.
---@param slot? integer Ignored by ESX inventories.
---@return boolean
function provider:removeItem(source, itemName, count, slot)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    xPlayer.removeInventoryItem(itemName, count or 1)
    return true
end

---Return the total quantity of `itemName` carried by the player.
---@param source integer
---@param itemName string
---@return integer
function provider:getItemCount(source, itemName)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    local item = xPlayer.getInventoryItem(itemName)
    return item and item.count or 0
end

---Whether the player carries at least `count` of `itemName` (default 1).
---@param source integer
---@param itemName string
---@param count? integer
---@return boolean
function provider:hasItem(source, itemName, count)
    return self:getItemCount(source, itemName) >= (count or 1)
end

---Whether the player has weight space for `count` units of `itemName`.
---@param source integer
---@param itemName string
---@param count integer
---@return boolean
function provider:canCarryItem(source, itemName, count)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    local item = xPlayer.getInventoryItem(itemName)
    if not item then return false end
    return (xPlayer.getMaxWeight() - xPlayer.getWeight()) >= (item.weight or 0) * (count or 1)
end

---Top up the player's ammo for a given weapon.
---@param source integer
---@param ammoItem string Ignored on ESX; ammo is bound directly to the weapon.
---@param weapon string
---@param amount integer
---@return boolean
function provider:addAmmo(source, ammoItem, weapon, amount)
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return false end
    xPlayer.addWeaponAmmo(weapon, amount or 1)
    return true
end

---Replace metadata on an item slot; ESX inventories do not support this.
---@param source integer
---@param itemName string
---@param slot integer
---@param metadata table
---@return boolean
function provider:setItemMetadata(source, itemName, slot, metadata)
    return false
end

---Return the item currently held in `slot`; ESX inventories are slotless.
---@param source integer
---@param slot integer
---@return table?
function provider:getItemBySlot(source, slot)
    return nil
end

---Whether per-item metadata survives across saves.
---@return boolean
function provider:supportsMetadata()
    return false
end
