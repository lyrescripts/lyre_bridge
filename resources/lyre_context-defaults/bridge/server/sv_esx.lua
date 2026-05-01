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

---hasPermission
---Checks if a player has any of the required groups/permissions
---@param source number The player source
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean Whether the player has permission
---@public
function bridge:hasPermission(source, groups)
	if not groups then return true end

	local xPlayer = self.object.GetPlayerFromId(source)
	if not xPlayer then return false end

	local playerJob = xPlayer.getJob()
	local playerGroup = xPlayer.getGroup()

	-- Build player groups table with grades
	local playerGroups = {}
	if playerJob and playerJob.name then
		playerGroups[playerJob.name] = playerJob.grade or 0
	end
	if playerGroup then
		playerGroups[playerGroup] = 0 -- Admin groups don't have grades
	end

	local groupsType = type(groups)

	if groupsType == 'string' then
		-- Single group: groups = "police"
		return playerGroups[groups] ~= nil
	elseif groupsType == 'table' then
		-- Check if it's an array or a dictionary
		-- Array: groups = { "police", "sheriff" }
		-- Dictionary: groups = { police = 2, sheriff = 3 }
		local isArray = #groups > 0

		if isArray then
			-- Array of groups - player must have at least one
			for i = 1, #groups do
				if playerGroups[groups[i]] ~= nil then
					return true
				end
			end
			return false
		else
			-- Dictionary of groups with grades - player must have at least one with sufficient grade
			for groupName, requiredGrade in pairs(groups) do
				local playerGrade = playerGroups[groupName]
				if playerGrade ~= nil and playerGrade >= requiredGrade then
					return true
				end
			end
			return false
		end
	end

	return true
end

---feedPlayer
---@param source number
---@return void
---@public
function bridge:feedPlayer(source)
	local xPlayer = self.object.GetPlayerFromId(source)
	if xPlayer then
		TriggerClientEvent("esx_status:set", source, "hunger", 1000000)
		TriggerClientEvent("esx_status:set", source, "thirst", 1000000)
	end
end
