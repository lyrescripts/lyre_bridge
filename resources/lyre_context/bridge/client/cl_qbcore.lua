_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qb-core")
end

local bridge = _G.bridge[this]

-- ACE permissions cache with rate limiting
local aceCache = {}
local lastAceRequest = 0
local ACE_RATE_LIMIT = 1000 -- 1 second in ms

-- Listen for ACE permission results from server
RegisterNetEvent("lyre_context:acePermissionsResult", function(results)
	if type(results) == "table" then
		for perm, hasIt in pairs(results) do
			aceCache[perm] = hasIt
		end
	end
end)

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qb-core"]:GetCoreObject()
end

---requestAcePermissions
---Requests ACE permissions from server (rate limited)
---@param permissions table Array of permission strings to check
local function requestAcePermissions(permissions)
	local now = GetGameTimer()
	if now - lastAceRequest < ACE_RATE_LIMIT then
		return -- Rate limited
	end
	lastAceRequest = now
	TriggerServerEvent("lyre_context:checkAcePermissions", permissions)
end

---hasPermission
---Checks if the player has any of the required groups/permissions
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean Whether the player has permission
---@public
function bridge:hasPermission(groups)
	if not groups then
		return true
	end

	local playerData = self.object.Functions.GetPlayerData()
	if not playerData then
		return false
	end

	-- Build player groups table with grades
	local playerGroups = {}
	if playerData.job and playerData.job.name then
		playerGroups[playerData.job.name] = playerData.job.grade and playerData.job.grade.level or 0
	end
	if playerData.gang and playerData.gang.name then
		playerGroups[playerData.gang.name] = playerData.gang.grade and playerData.gang.grade.level or 0
	end

	local groupsType = type(groups)

	if groupsType == "string" then
		-- Single group: groups = "police"
		if playerGroups[groups] ~= nil then
			return true
		end
		-- Check ACE permissions from cache
		if aceCache[groups] then
			return true
		end
		-- Request update from server (rate limited)
		requestAcePermissions({ groups })
		return false
	elseif groupsType == "table" then
		-- Check if it's an array or a dictionary
		-- Array: groups = { "police", "sheriff" }
		-- Dictionary: groups = { police = 2, sheriff = 3 }
		local isArray = #groups > 0

		if isArray then
			local permsToCheck = {}
			-- Array of groups - player must have at least one
			for i = 1, #groups do
				if playerGroups[groups[i]] ~= nil then
					return true
				end
				-- Check ACE permissions from cache
				if aceCache[groups[i]] then
					return true
				end
				-- Collect permissions to request
				permsToCheck[#permsToCheck + 1] = groups[i]
			end
			-- Request update from server (rate limited)
			if #permsToCheck > 0 then
				requestAcePermissions(permsToCheck)
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
