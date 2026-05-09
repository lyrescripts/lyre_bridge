local bridge = LyreBridge.bridgeCandidate("ESX")

---getPlayerName
---@param playerId number
---@return string
function bridge:getPlayerName(playerId)
	local xPlayer = self.object.GetPlayerFromId(playerId)
	if xPlayer and xPlayer.getName then
		return xPlayer.getName()
	end

	return GetPlayerName(playerId) or ("Player " .. tostring(playerId))
end

---showNotification
---@param playerId number
---@param message string
function bridge:showNotification(playerId, message)
	local xPlayer = self.object.GetPlayerFromId(playerId)
	if xPlayer and xPlayer.showNotification then
		xPlayer.showNotification(message)
	end
end

---getPlayersByJobs
---@param jobs table
---@return table
function bridge:getPlayersByJobs(jobs)
	local jobMap = {}
	local players = {}

	for _, jobName in ipairs(jobs or {}) do
		jobMap[jobName] = true
	end

	for _, playerId in ipairs(GetPlayers()) do
		local xPlayer = self.object.GetPlayerFromId(tonumber(playerId))
		if xPlayer and xPlayer.job and jobMap[xPlayer.job.name] then
			if not Config.ems.requireOnDuty or (xPlayer.job.onduty ~= false and xPlayer.job.onDuty ~= false) then
				players[#players + 1] = tonumber(playerId)
			end
		end
	end

	return players
end

---clearDeathStatus
---@param playerId number
function bridge:clearDeathStatus(playerId)
	-- ESX ambulance resources generally keep their death state client-side.
end
