local provider = LyreBridge.registerProvider("client", "inventory", "tgiann_inventory", 15)

---@return boolean
function provider:detect()
    return bridge.core.isStarted("tgiann-inventory")
    and not bridge.core.isStarted("ox_inventory")
end

---@param itemName string
---@param amount? integer
---@return boolean
function provider:hasItem(itemName, amount)
    local result = exports["tgiann-inventory"]:HasItem(itemName, amount or 1)
    if result ~= nil then
        return result ~= false
    end

    local count = exports["tgiann-inventory"]:GetItemCount(itemName) or 0
    return tonumber(count) >= (amount or 1)
end
