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
