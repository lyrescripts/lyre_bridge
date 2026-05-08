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
	self.object = exports["qbx_core"]
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
