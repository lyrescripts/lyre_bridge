_G.bridge = _G.bridge or {}

local this = "EXAMPLE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	-- Return true if your framework is detected
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
	-- Initialize your framework here
end

---hasPermission
---Checks if a player has any of the required groups/permissions
---@param source number The player source
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean Whether the player has permission
---@public
function bridge:hasPermission(source, groups)
	-- Check if player has any of the required groups/permissions
	-- groups can be:
	--   nil (always true)
	--   string: "police"
	--   array: { "police", "sheriff" }
	--   dictionary with grades: { police = 2, sheriff = 3 }
	if not groups then return true end

	-- Implement your permission check here
	-- You should build a playerGroups table like: { ["police"] = 2, ["admin"] = 0 }
	-- Then compare against the groups parameter
	return false
end

---feedPlayer
---@param source number
---@return void
---@public
function bridge:feedPlayer(source)
	-- Implement your feed player logic here
	-- Set hunger and thirst to max values
end
