_G.bridge = _G.bridge or {}

local this = "ESX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("es_extended") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["es_extended"]:getSharedObject()
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

	local xPlayers = self.object.GetExtendedPlayers()
	for _, xPlayer in pairs(xPlayers) do
		local ped = GetPlayerPed(xPlayer.source)
		local playerCoords = GetEntityCoords(ped)

		local distance = #(coords - playerCoords)

		if distance <= radius and not exceptions[xPlayer.source] then
			if getDeadPlayers or not (GetEntityHealth(ped) <= 0) then
				table.insert(players, {
					serverId = xPlayer.source,
					name = xPlayer.getName(),
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
	local xPlayer = self.object.GetPlayerFromId(source)

	if not xPlayer then
		return false
	end

	return xPlayer.getIdentifier() or false
end

---getOnlineCops
---@return number
---@public
function bridge:getOnlineCops()
	local xPlayers = self.object.GetExtendedPlayers()
	local cops = 0

	for _, xPlayer in pairs(xPlayers) do
		if xPlayer.getJob().name == "police" then
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
	local xPlayers = self.object.GetExtendedPlayers()
	local players = {}

	for _, xPlayer in pairs(xPlayers) do
		if xPlayer.getJob().name == jobName then
			table.insert(players, xPlayer.source)
		end
	end

	return players
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
