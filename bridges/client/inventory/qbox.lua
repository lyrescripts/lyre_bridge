local provider = LyreBridge.registerProvider("client", "inventory", "qbox", 40)

---Active when `qbx_core` is the only inventory source running.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core")
    and not bridge.core.isStarted("ox_inventory")
end

---Whether the local player carries at least `amount` of `itemName`.
---@param itemName string
---@param amount? integer Defaults to 1.
---@return boolean
function provider:hasItem(itemName, amount)
    local items = exports.qbx_core:GetPlayerData().items or {}
    local total = 0
    for _, item in pairs(items) do
        if item and item.name == itemName then
            total = total + (item.amount or item.count or 1)
        end
    end
    return total >= (amount or 1)
end
