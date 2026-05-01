_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("qbx_core") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qbx_core"]
end

---getPlayerName
---@param playerId number
---@return string
---@public
function bridge:getPlayerName(playerId)
	local player = self.object:GetPlayer(playerId)
	local playerData = player and player.PlayerData or player
	local charinfo = playerData and playerData.charinfo

	if charinfo then
		local firstName = charinfo.firstname or charinfo.firstName or ""
		local lastName = charinfo.lastname or charinfo.lastName or ""
		local fullName = (firstName .. " " .. lastName):gsub("^%s*(.-)%s*$", "%1")

		if fullName ~= "" then
			return fullName
		end
	end

	return GetPlayerName(playerId) or ("Player " .. tostring(playerId))
end

---showNotification
---@param playerId number
---@param message string
---@return void
---@public
function bridge:showNotification(playerId, message)
	local success = pcall(function()
		self.object:Notify(playerId, message, "inform", 5000)
	end)

	if not success then
		TriggerClientEvent(resourceName .. ":client:notify", playerId, message, "primary")
	end
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

	local playersData = self.object:GetPlayersData() or {}
	for _, playerData in pairs(playersData) do
		local source = tonumber(playerData.source)
		local activeJob = playerData.job
		local hasJob = activeJob and activeJob.name and jobMap[activeJob.name] or false

		if not hasJob and type(playerData.jobs) == "table" then
			for jobName in pairs(playerData.jobs) do
				if jobMap[jobName] then
					hasJob = true
					break
				end
			end
		end

		if source and hasJob and (not Config.ems.requireOnDuty or not activeJob or activeJob.onduty ~= false) then
			players[#players + 1] = source
		end
	end

	return players
end

---clearDeathStatus
---@param playerId number
---@return void
---@public
function bridge:clearDeathStatus(playerId)
	pcall(function()
		self.object:SetMetadata(playerId, "isdead", false)
	end)

	pcall(function()
		self.object:SetMetadata(playerId, "inlaststand", false)
	end)
end
