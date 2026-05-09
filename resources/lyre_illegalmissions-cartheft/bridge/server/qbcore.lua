local bridge = LyreBridge.bridgeCandidate("QBCORE")

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
