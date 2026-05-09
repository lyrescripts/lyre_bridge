local bridge = LyreBridge.bridgeCandidate("STANDALONE")

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
	TriggerClientEvent(resourceName .. ":client:notify", playerId, message, "primary")
end

---getPlayersByJobs
---@param jobs table
---@return table
---@public
function bridge:getPlayersByJobs(jobs)
	return {}
end

---clearDeathStatus
---@param playerId number
---@return void
---@public
function bridge:clearDeathStatus(playerId)
end
