_G.bridge = _G.bridge or {}

local this = "ESX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("es_extended")
end

local bridge = _G.bridge[this]

function bridge:init()
	local framework = LyreBridge.getModule("server", "framework")
	if framework and framework.getESX then
		self.object = framework.getESX()
	end
end
