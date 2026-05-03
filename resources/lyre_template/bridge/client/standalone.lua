_G.bridge = _G.bridge or {}

local this = "STANDALONE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return true
end

local bridge = _G.bridge[this]

function bridge:init()
end
