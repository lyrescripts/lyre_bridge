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

---getPlayersInZone
---@param coords vector3
---@param radius number
---@param exceptions table
---@param getDeadPlayers boolean
---@return table
---@public
function bridge:getPlayersInZone(coords, radius, exceptions, getDeadPlayers)
	local players = {}
	exceptions = exceptions or {}

	for playerId, player in pairs(self.object:GetQBPlayers() or {}) do
		playerId = tonumber(playerId)
		local ped = GetPlayerPed(playerId)
		local playerCoords = GetEntityCoords(ped)

		local distance = #(coords - playerCoords)

		if distance <= radius and not exceptions[playerId] then
			if getDeadPlayers or not (GetEntityHealth(ped) <= 0) then
				table.insert(players, {
					serverId = playerId,
					name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
				})
			end
		end
	end

	return players
end

---getIdentifierFromSource
---@param source number
---@return string
---@public
function bridge:getIdentifierFromSource(source)
	local player = self.object:GetPlayer(source)

	if not player then
		return false
	end

	return player.PlayerData.license or false
end

---getOnlineCops
---@return number
---@public
function bridge:getOnlineCops()
	local cops = 0

	for _, player in pairs(self.object:GetQBPlayers() or {}) do
		if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
			cops = cops + 1
		end
	end

	return cops
end

---getOnlinePlayersInJob
---@param jobName string
---@return table
---@public
function bridge:getOnlinePlayersInJob(jobName)
	local jobPlayers = {}

	for playerId, player in pairs(self.object:GetQBPlayers() or {}) do
		if player.PlayerData.job.name == jobName and player.PlayerData.job.onduty then
			table.insert(jobPlayers, tonumber(playerId))
		end
	end

	return jobPlayers
end

---alertJob
---@param jobName string
---@param coords table
---@param radius number
---@param title string
---@param description string
---@param teamMembers table
---@return void
---@public
function bridge:alertJob(jobName, coords, radius, title, description, teamMembers)
	if GetResourceState("rcore_dispatch") == "started" then
		local rcoredispatch = {
			code = "10-64",
			default_priority = "medium",
			coords = coords,
			job = jobName,
			text = description,
			type = "alerts",
			blip_time = 5,
			blip = {
				sprite = 161,
				colour = 1,
				scale = 1.0,
				text = title,
				radius = radius or 50.0,
			},
		}
		TriggerEvent("rcore_dispatch:server:sendAlert", rcoredispatch)
	elseif GetResourceState("ps-dispatch") == "started" then
		local dispatchData = {
			message = title,
			codeName = "911call",
			code = "10-64",
			icon = "fas fa-skull-crossbones",
			priority = 2,
			coords = coords,
			description = description,
			jobs = { jobName },
		}
		TriggerEvent("ps-dispatch:server:notify", dispatchData)
	else
		local players = self:getOnlinePlayersInJob(jobName)

		if not players then
			return
		end

		for _, player in pairs(players) do
			TriggerClientEvent("lyre_illegalmissions:alert", player, jobName, coords, radius, title, description)
		end
	end
end

---onMissionEnd
---@param type string
---@param success boolean
---@param teamMembers table
---@return void
function bridge:onMissionEnd(type, success, teamMembers)
	-- Example of argument values
	-- type = "gofast" -- Mission type
	-- success = true -- If the mission was successful
	-- teamMembers = {1, 2, 3, 4, 5} -- The members server id of the team
end
