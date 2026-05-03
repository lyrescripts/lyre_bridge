_G.bridge = _G.bridge or {}

local this = "ESX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("es_extended")
end

local bridge = _G.bridge[this]

function bridge:init()
	local ok, object = pcall(function()
		return exports["es_extended"]:getSharedObject()
	end)

	if ok then
		self.object = object
	end
end
