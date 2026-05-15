local provider = LyreBridge.registerProvider("client", "vehicles", "qbox", 5)

---Active when the `qbx_core` resource is started. qbox ships with ox_lib so
---vehicle property serialization is delegated there.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core") and bridge.core.isStarted("ox_lib")
end

---Serialize the visual properties of `vehicle` through `ox_lib`.
---@param vehicle integer
---@return table properties
function provider:getProperties(vehicle)
    return lib.getVehicleProperties(vehicle)
end

---Apply previously-serialized properties to `vehicle` through `ox_lib`.
---@param vehicle integer
---@param properties table
function provider:applyProperties(vehicle, properties)
    lib.setVehicleProperties(vehicle, properties)
end
