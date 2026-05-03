_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qbx_core")
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	local ok, object = pcall(function()
		return exports["qbx_core"]
	end)

	if ok then
		self.object = object
	end
end
