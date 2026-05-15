local provider = LyreBridge.registerProvider("server", "status", "esx", 10)

---Active when the `es_extended` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
end

---Restore hunger and thirst to full via `esx_status`.
---@param source integer
function provider:feed(source)
    TriggerClientEvent("esx_status:set", source, "hunger", 1000000)
    TriggerClientEvent("esx_status:set", source, "thirst", 1000000)
end

---Override the player's hunger value (ESX scale is 0-1000000).
---@param source integer
---@param value number
function provider:setHunger(source, value)
    TriggerClientEvent("esx_status:set", source, "hunger", value)
end

---Override the player's thirst value (ESX scale is 0-1000000).
---@param source integer
---@param value number
function provider:setThirst(source, value)
    TriggerClientEvent("esx_status:set", source, "thirst", value)
end
