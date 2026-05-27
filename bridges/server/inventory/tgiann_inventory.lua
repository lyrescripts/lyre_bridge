local provider = LyreBridge.registerProvider("server", "inventory", "tgiann_inventory", 15)

---@return boolean
function provider:detect()
    return bridge.core.isStarted("tgiann-inventory")
    and not bridge.core.isStarted("ox_inventory")
end

---@param source integer
---@param itemName string
---@param count integer
---@param metadata? table
---@return boolean
function provider:addItem(source, itemName, count, metadata)
    return exports["tgiann-inventory"]:AddItem(source, itemName, count or 1, nil, metadata) ~= false
end

---@param source integer
---@param itemName string
---@param count integer
---@param slot? integer
---@return boolean
function provider:removeItem(source, itemName, count, slot)
    return exports["tgiann-inventory"]:RemoveItem(source, itemName, count or 1, slot) ~= false
end

---@param source integer
---@param itemName string
---@return integer
function provider:getItemCount(source, itemName)
    return tonumber(exports["tgiann-inventory"]:GetItemCount(source, itemName)) or 0
end

---@param source integer
---@param itemName string
---@param count? integer
---@return boolean
function provider:hasItem(source, itemName, count)
    local result = exports["tgiann-inventory"]:HasItem(source, itemName, count or 1)
    if result ~= nil then
        return result ~= false
    end

    return self:getItemCount(source, itemName) >= (count or 1)
end

---@param source integer
---@param itemName string
---@param count integer
---@return boolean
function provider:canCarryItem(source, itemName, count)
    return exports["tgiann-inventory"]:CanCarryItem(source, itemName, count or 1) ~= false
end

---@param source integer
---@param ammoItem string
---@param weapon string
---@param amount integer
---@return boolean
function provider:addAmmo(source, ammoItem, weapon, amount)
    return self:addItem(source, ammoItem, amount)
end

---@param source integer
---@param itemName string
---@param slot integer
---@param metadata table
---@return boolean
function provider:setItemMetadata(source, itemName, slot, metadata)
    local ok, result = pcall(function()
        return exports["tgiann-inventory"]:UpdateItemMetadata(source, itemName, slot, metadata)
    end)
    if ok then
        return result ~= false
    end

    ok, result = pcall(function()
        return exports["tgiann-inventory"]:SetItemData(source, itemName, slot, metadata)
    end)
    if ok then
        return result ~= false
    end

    return false
end

---@param source integer
---@param slot integer
---@return table?
function provider:getItemBySlot(source, slot)
    return exports["tgiann-inventory"]:GetItemBySlot(source, slot)
end

---@return boolean
function provider:supportsMetadata()
    return true
end
