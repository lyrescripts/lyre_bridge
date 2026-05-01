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

---hasPermission
---Checks if a player has any of the required groups/permissions
---@param source number The player source
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean Whether the player has permission
---@public
function bridge:hasPermission(source, groups)
	if not groups then return true end

	local Player = self.object.Functions.GetPlayer(source)
	if not Player then return false end

	local playerJob = Player.PlayerData.job
	local playerGang = Player.PlayerData.gang

	-- Build player groups table with grades
	local playerGroups = {}
	if playerJob and playerJob.name then
		playerGroups[playerJob.name] = playerJob.grade and playerJob.grade.level or 0
	end
	if playerGang and playerGang.name then
		playerGroups[playerGang.name] = playerGang.grade and playerGang.grade.level or 0
	end

	local groupsType = type(groups)

	if groupsType == 'string' then
		-- Single group: groups = "police"
		-- Also check QBCore permissions for admin groups
		if playerGroups[groups] ~= nil then
			return true
		end
		return self.object.Functions.HasPermission(source, groups)
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
				-- Also check QBCore permissions
				if self.object.Functions.HasPermission(source, groups[i]) then
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
	local Player = self.object.Functions.GetPlayer(source)
	if Player then
		Player.Functions.SetMetaData("hunger", 100)
		Player.Functions.SetMetaData("thirst", 100)
		TriggerClientEvent("hud:client:UpdateNeeds", source, 100, 100)
	end
end
