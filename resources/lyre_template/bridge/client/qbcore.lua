_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qb-core")
end

local bridge = _G.bridge[this]

function bridge:init()
	local ok, object = pcall(function()
		return exports["qb-core"]:GetCoreObject()
	end)

	if ok then
		self.object = object
	end
end
