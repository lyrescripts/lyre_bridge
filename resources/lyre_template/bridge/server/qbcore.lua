_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qb-core")
end

local bridge = _G.bridge[this]

function bridge:init()
	local framework = LyreBridge.getModule("server", "framework")
	if framework and framework.getQBCore then
		self.object = framework.getQBCore()
	end
end
