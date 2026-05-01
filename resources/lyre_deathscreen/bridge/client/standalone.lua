_G.bridge = _G.bridge or {}

local this = "STANDALONE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return true
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
end

---revivePlayer
---@return boolean
---@public
function bridge:revivePlayer()
	return false
end
