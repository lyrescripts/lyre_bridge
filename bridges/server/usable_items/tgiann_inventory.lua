local provider = LyreBridge.registerProvider("server", "usable_items", "tgiann_inventory", 15)

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
---@param callback fun(source: integer, item?: table)
function provider:register(itemName, callback)
    local ok = pcall(function()
        exports[self.resourceName]:RegisterUsableItem(itemName, function(source, item)
            callback(source, item)
        end)
    end)

    if ok then
        return
    end

    ok = pcall(function()
        exports[self.resourceName]:CreateUsableItem(itemName, function(source, item)
            callback(source, item)
        end)
    end)

    if ok then
        return
    end

    pcall(function()
        exports[self.resourceName]:CreateUseableItem(itemName, function(source, item)
            callback(source, item)
        end)
    end)
end
