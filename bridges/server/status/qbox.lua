local provider = LyreBridge.registerProvider("server", "status", "qbox", 5)

---Active when the `qbx_core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core")
end

---Cache the qbx_core exports proxy for later calls.
function provider:init()
    self.object = exports.qbx_core
end

---@param source integer
---@return table?
function provider:__getPlayer(source)
    return self.object:GetPlayer(source)
end

---Restore hunger and thirst to full via player metadata + HUD update.
---@param source integer
function provider:feed(source)
    local player = self:__getPlayer(source)
    if not player or not player.Functions then return end
    player.Functions.SetMetaData("hunger", 100)
    player.Functions.SetMetaData("thirst", 100)
    TriggerClientEvent("hud:client:UpdateNeeds", source, 100, 100)
end

---Override the player's hunger value (qbox scale is 0-100).
---@param source integer
---@param value number
function provider:setHunger(source, value)
    local player = self:__getPlayer(source)
    if not player or not player.Functions then return end
    player.Functions.SetMetaData("hunger", value)
    TriggerClientEvent("hud:client:UpdateNeeds", source, value, nil)
end

---Override the player's thirst value (qbox scale is 0-100).
---@param source integer
---@param value number
function provider:setThirst(source, value)
    local player = self:__getPlayer(source)
    if not player or not player.Functions then return end
    player.Functions.SetMetaData("thirst", value)
    TriggerClientEvent("hud:client:UpdateNeeds", source, nil, value)
end
