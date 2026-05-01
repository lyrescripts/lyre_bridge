_G.bridge = _G.bridge or {}

local this = "EXAMPLE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	-- Customize this function
	return false
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---getPlayerFromId
---@param playerId number
---@return table
---@public
function bridge:getPlayerFromId(playerId)
	local player = {}

	player.getName = function()
		-- Customize this function
		return "John Doe"
	end

	player.getFirstName = function()
		-- Customize this function
		return "John"
	end

	player.getLastName = function()
		-- Customize this function
		return "Doe"
	end

	player.showNotification = function(message)
		-- Customize this function
	end

	player.getAccount = function(account)
		-- Customize this function
		return 0
	end

	player.removeAccountMoney = function(account, amount)
		-- Customize this function
	end

	player.addAccountMoney = function(account, amount)
		-- Customize this function
	end

	return player
end

---getPlayersInZone
---@param coords vector3
---@param radius number
---@param exceptions table
---@param getDeadPlayers boolean
---@return table
---@public
function bridge:getPlayersInZone(coords, radius, exceptions, getDeadPlayers)
	-- Customize this function
	return {}
end

---getIdentifierFromSource
---@param source number
---@return string
---@public
function bridge:getIdentifierFromSource(source)
	-- Customize this function
	return ""
end

---getOnlineCops
---@return number
---@public
function bridge:getOnlineCops()
	-- Customize this function
	return 0
end

---getOnlinePlayersInJob
---@param jobName string
---@return table
---@public
function bridge:getOnlinePlayersInJob(jobName)
	-- Customize this function
	return {}
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
