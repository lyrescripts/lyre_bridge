local bridge = LyreBridge.bridgeCandidate("STANDALONE")

---hasPermission
---Without a framework, fall back to ACE permissions. Group strings are
---checked against the matching ACE name (e.g. "police" → "command.police").
---@param source number The player source
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean
function bridge:hasPermission(source, groups)
	if not groups then return true end

	local function hasAce(group)
		return IsPlayerAceAllowed(source, "command." .. group)
			or IsPlayerAceAllowed(source, "group." .. group)
			or IsPlayerAceAllowed(source, group)
	end

	if type(groups) == "string" then
		return hasAce(groups)
	end

	if type(groups) == "table" then
		local isArray = #groups > 0
		if isArray then
			for i = 1, #groups do
				if hasAce(groups[i]) then
					return true
				end
			end
			return false
		end

		for groupName, _ in pairs(groups) do
			if hasAce(groupName) then
				return true
			end
		end
		return false
	end

	return true
end

---feedPlayer
---Without a framework, status is not centrally tracked. No-op.
---@param source number
function bridge:feedPlayer(source)
	-- No status system in standalone mode.
end
