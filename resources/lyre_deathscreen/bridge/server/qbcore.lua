_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("qb-core") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qb-core"]:GetCoreObject()
end

---getPlayerName
---@param playerId number
---@return string
---@public
function bridge:getPlayerName(playerId)
	local qPlayer = self.object.Functions.GetPlayer(playerId)
	if qPlayer and qPlayer.PlayerData and qPlayer.PlayerData.charinfo then
		local charinfo = qPlayer.PlayerData.charinfo
		return (charinfo.firstname or "") .. " " .. (charinfo.lastname or "")
	end

	return GetPlayerName(playerId) or ("Player " .. tostring(playerId))
end

---showNotification
---@param playerId number
---@param message string
---@return void
---@public
function bridge:showNotification(playerId, message)
	TriggerClientEvent("QBCore:Notify", playerId, message, "primary", 5000)
end

---getPlayersByJobs
---@param jobs table
---@return table
---@public
function bridge:getPlayersByJobs(jobs)
	local jobMap = {}
	local players = {}

	for _, jobName in ipairs(jobs or {}) do
		jobMap[jobName] = true
	end

	local qbPlayers = self.object.Functions.GetQBPlayers and self.object.Functions.GetQBPlayers() or self.object.Players or {}
	for source, qPlayer in pairs(qbPlayers) do
		local job = qPlayer.PlayerData and qPlayer.PlayerData.job
		if job and job.name and jobMap[job.name] then
			if not Config.ems.requireOnDuty or job.onduty ~= false then
				players[#players + 1] = tonumber(qPlayer.PlayerData.source or source)
			end
		end
	end

	return players
end

---clearDeathStatus
---@param playerId number
---@return void
---@public
function bridge:clearDeathStatus(playerId)
	local qPlayer = self.object.Functions.GetPlayer(playerId)
	if not qPlayer then
		return
	end

	if qPlayer.Functions and qPlayer.Functions.SetMetaData then
		qPlayer.Functions.SetMetaData("isdead", false)
		qPlayer.Functions.SetMetaData("inlaststand", false)
	end
end
