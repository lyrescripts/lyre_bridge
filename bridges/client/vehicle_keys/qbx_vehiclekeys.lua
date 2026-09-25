local provider = LyreBridge.registerProvider("client", "vehicle_keys", "qbx_vehiclekeys", 10)

---Active when the `qbx_vehiclekeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_vehiclekeys")
end

-- Plate-based events from qbx_vehiclekeys' qb bridge: the server waits for
-- freshly spawned vehicles before resolving the plate, unlike the netId path.

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    TriggerServerEvent("qb-vehiclekeys:server:removeKeys", plate)
end
