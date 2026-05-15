local provider = LyreBridge.registerProvider("client", "inventory", "qb", 50)

---Active when `qb-core` is the only inventory source running.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
    and not bridge.core.isStarted("ox_inventory")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Whether the local player carries at least `amount` of `itemName`.
---@param itemName string
---@param amount? integer Defaults to 1.
---@return boolean
function provider:hasItem(itemName, amount)
    local playerData = self.object.Functions.GetPlayerData()
    local items = playerData and playerData.items or {}
    local total = 0
    for _, item in pairs(items) do
        if item and item.name == itemName then
            total = total + (item.amount or item.count or 1)
        end
    end
    return total >= (amount or 1)
end
