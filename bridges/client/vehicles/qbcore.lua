local provider = LyreBridge.registerProvider("client", "vehicles", "qbcore", 20)

---Active when the `qb-core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Serialize the visual properties of `vehicle` through `QBCore.Functions`.
---@param vehicle integer
---@return table properties
function provider:getProperties(vehicle)
    return self.object.Functions.GetVehicleProperties(vehicle)
end

---Apply previously-serialized properties to `vehicle` through `QBCore.Functions`.
---@param vehicle integer
---@param properties table
function provider:applyProperties(vehicle, properties)
    self.object.Functions.SetVehicleProperties(vehicle, properties)
end
