local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Return true when your framework/resource should use this bridge.
    return false
end

---init
---@return void
---@public
function bridge:init()
	-- Initialize your framework object here when needed.
end

---getPlayerName
---@param playerId number
---@return string
---@public
function bridge:getPlayerName(playerId)
	return GetPlayerName(playerId) or ("Player " .. tostring(playerId))
end

---showNotification
---@param playerId number
---@param message string
---@return void
---@public
function bridge:showNotification(playerId, message)
	-- Replace this with your notification system.
	TriggerClientEvent(resourceName .. ":client:notify", playerId, message, "primary")
end

---getPlayersByJobs
---@param jobs table
---@return table
---@public
function bridge:getPlayersByJobs(jobs)
	-- Return the server IDs that should receive built-in EMS alerts.
	return {}
end

---clearDeathStatus
---@param playerId number
---@return void
---@public
function bridge:clearDeathStatus(playerId)
	-- Clear your framework dead/laststand metadata here if it has any.
end
