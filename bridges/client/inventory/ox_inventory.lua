local provider = LyreBridge.registerProvider("client", "inventory", "ox_inventory", 10)

---Active when the `ox_inventory` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ox_inventory")
end

---Whether the local player carries at least `amount` of `itemName`.
---@param itemName string
---@param amount? integer Defaults to 1.
---@return boolean
function provider:hasItem(itemName, amount)
    local count = exports.ox_inventory:Search("count", itemName) or 0
    return count >= (amount or 1)
end
