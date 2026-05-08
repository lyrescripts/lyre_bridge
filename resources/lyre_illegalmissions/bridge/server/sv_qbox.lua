_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qbx_core")
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
	local handled = self:sendDispatchAlert({
		code = "10-64",
		title = title,
		message = description,
		description = description,
		icon = "fas fa-skull-crossbones",
		priority = 2,
		coords = coords,
		jobs = { jobName },
		dispatchType = "alerts",
		blip = {
			sprite = 161,
			color = 1,
			scale = 1.0,
			label = title,
			duration = 5000,
			radius = radius or 50.0,
		},
	}, { provider = "auto_detect" })

	if handled then
		return
	end

	local players = self:getOnlinePlayersInJob(jobName)

	if not players then
		return
	end

	for _, player in pairs(players) do
		TriggerClientEvent("lyre_illegalmissions:alert", player, jobName, coords, radius, title, description)
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
