local bridge = LyreBridge.bridgeCandidate("ESX")

---hasPermission
---Checks if the player has any of the required groups/permissions
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean Whether the player has permission
---@public
function bridge:hasPermission(groups)
	if not groups then
		return true
	end

	local playerData = self.object.GetPlayerData()
	if not playerData then
		return false
	end

	-- Build player groups table with grades
	local playerGroups = {}
	if playerData.job and playerData.job.name then
		playerGroups[playerData.job.name] = playerData.job.grade or 0
	end
	if playerData.group then
		playerGroups[playerData.group] = 0 -- Admin groups don't have grades
	end

	local groupsType = type(groups)

	if groupsType == "string" then
		-- Single group: groups = "police"
		return playerGroups[groups] ~= nil
	elseif groupsType == "table" then
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

---hasItem
---Checks if the player has a specific item with a minimum amount
---@param item string The item name
---@param amount number|nil The minimum amount required (default 1)
---@return boolean Whether the player has the item
---@public
function bridge:hasItem(item, amount)
	local module = LyreBridge.getModule("client", "inventory")
	return module and module.hasItem(self, item, amount) or false
end
