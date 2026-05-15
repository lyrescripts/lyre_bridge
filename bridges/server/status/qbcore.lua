local provider = LyreBridge.registerProvider("server", "status", "qbcore", 20)

---Active when the `qb-core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---@param source integer
---@return table?
function provider:__getPlayer(source)
    return self.object.Functions.GetPlayer(source)
end

---Restore hunger and thirst to full via QBCore metadata + HUD update.
---@param source integer
function provider:feed(source)
    local player = self:__getPlayer(source)
    if not player then return end
    player.Functions.SetMetaData("hunger", 100)
    player.Functions.SetMetaData("thirst", 100)
    TriggerClientEvent("hud:client:UpdateNeeds", source, 100, 100)
end

---Override the player's hunger value (QBCore scale is 0-100).
---@param source integer
---@param value number
function provider:setHunger(source, value)
    local player = self:__getPlayer(source)
    if not player then return end
    player.Functions.SetMetaData("hunger", value)
    TriggerClientEvent("hud:client:UpdateNeeds", source, value, nil)
end

---Override the player's thirst value (QBCore scale is 0-100).
---@param source integer
---@param value number
function provider:setThirst(source, value)
    local player = self:__getPlayer(source)
    if not player then return end
    player.Functions.SetMetaData("thirst", value)
    TriggerClientEvent("hud:client:UpdateNeeds", source, nil, value)
end
