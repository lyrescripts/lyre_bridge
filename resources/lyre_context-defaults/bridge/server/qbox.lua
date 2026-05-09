local bridge = LyreBridge.bridgeCandidate("QBOX")

local function hasAcePermission(source, permission)
	return IsPlayerAceAllowed(source, permission) or IsPlayerAceAllowed(source, "group." .. permission)
end

local function getPlayerGroups(object, source, primaryGroups)
	local groups = primaryGroups or {}

	if object and type(object.GetGroups) == "function" then
		for groupName, grade in pairs(object:GetGroups(source) or {}) do
			groups[groupName] = grade
		end
	end

	return groups
end

---hasPermission
---Checks if a player has any of the required groups/permissions
---@param source number The player source
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean Whether the player has permission
---@public
function bridge:hasPermission(source, groups)
	if not groups then return true end

	local Player = self.object:GetPlayer(source)
	if not Player then return false end

	local playerJob = Player.PlayerData.job
	local playerGang = Player.PlayerData.gang

	local playerGroups = {}
	if playerJob and playerJob.name then
		playerGroups[playerJob.name] = playerJob.grade and playerJob.grade.level or 0
	end
	if playerGang and playerGang.name then
		playerGroups[playerGang.name] = playerGang.grade and playerGang.grade.level or 0
	end
	playerGroups = getPlayerGroups(self.object, source, playerGroups)

	local groupsType = type(groups)

	if groupsType == 'string' then
		-- Single group: groups = "police"
		if playerGroups[groups] ~= nil then
			return true
		end
		return hasAcePermission(source, groups)
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
				if hasAcePermission(source, groups[i]) then
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
	local Player = self.object:GetPlayer(source)
	if Player then
		Player.Functions.SetMetaData("hunger", 100)
		Player.Functions.SetMetaData("thirst", 100)
		TriggerClientEvent("hud:client:UpdateNeeds", source, 100, 100)
	end
end
