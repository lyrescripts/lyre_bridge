local provider = LyreBridge.registerProvider("client", "inventory", "esx", 70)

---Active when `es_extended` is the only inventory source running.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
    and not bridge.core.isStarted("ox_inventory")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Whether the local player carries at least `amount` of `itemName`.
---@param itemName string
---@param amount? integer Defaults to 1.
---@return boolean
function provider:hasItem(itemName, amount)
    local playerData = self.object.GetPlayerData()
    local inventory = playerData and playerData.inventory or {}
    for _, item in ipairs(inventory) do
        if item.name == itemName and (item.count or 0) >= (amount or 1) then
            return true
        end
    end
    return false
end
