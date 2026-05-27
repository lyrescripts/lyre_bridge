local provider = LyreBridge.registerProvider("client", "inventory", "tgiann_inventory", 15)

---Resolve the active TGIANN inventory resource name.
---@return string resourceName The resource name to call.
local function getResourceName()
    if bridge.core.isStarted("tgiann-inventory") then
        return "tgiann-inventory"
    end

    if bridge.core.isStarted("tgiann_inventory") then
        return "tgiann_inventory"
    end

    return "tgiann-inventory"
end

---@return boolean
function provider:detect()
    return (bridge.core.isStarted("tgiann-inventory") or bridge.core.isStarted("tgiann_inventory"))
    and not bridge.core.isStarted("ox_inventory")
end

---Cache the active resource name.
function provider:init()
    self.resourceName = getResourceName()
end

---@param itemName string
---@param amount? integer
---@return boolean
function provider:hasItem(itemName, amount)
    local result = exports[self.resourceName]:HasItem(itemName, amount or 1)
    if result ~= nil then
        return result ~= false
    end

    local count = exports[self.resourceName]:GetItemCount(itemName) or 0
    return tonumber(count) >= (amount or 1)
end
