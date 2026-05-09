local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Customize this function
    return false
end

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
