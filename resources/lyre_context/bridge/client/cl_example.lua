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

---hasPermission
---Checks if the player has any of the required groups/permissions
---@param groups string|table|nil The required groups (string, array, or dictionary with grades)
---@return boolean Whether the player has permission
---@public
function bridge:hasPermission(groups)
	-- Customize this function to check if the player has any of the required groups/permissions
	-- groups can be:
	--   nil (always true)
	--   string: "police"
	--   array: { "police", "sheriff" }
	--   dictionary with grades: { police = 2, sheriff = 3 }
	if not groups then
		return true
	end

	-- Build a playerGroups table like: { ["police"] = 2, ["admin"] = 0 }
	-- Then compare against the groups parameter
	return true
end

---hasItem
---Checks if the player has a specific item with a minimum amount
---@param item string The item name
---@param amount number|nil The minimum amount required (default 1)
---@return boolean Whether the player has the item
---@public
function bridge:hasItem(item, amount)
	-- Customize this function to check if the player has the specified item with the required amount
	return true
end
