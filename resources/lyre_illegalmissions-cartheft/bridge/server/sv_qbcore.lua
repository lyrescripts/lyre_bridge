_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qb-core")
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qb-core"]:GetCoreObject()
end

---unlockVehicle
---@param source number
---@param vehicle table
---@return void
---@public
function bridge:unlockVehicle(source, vehicle)
	local vehicle = NetworkGetEntityFromNetworkId(vehicle)
	if not DoesEntityExist(vehicle) then
		return
	end
	SetVehicleDoorsLocked(vehicle, 1)
end
