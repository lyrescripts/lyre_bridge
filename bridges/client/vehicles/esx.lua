local provider = LyreBridge.registerProvider("client", "vehicles", "esx", 10)

---Active when the `es_extended` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Serialize the visual properties of `vehicle` through `ESX.Game`.
---@param vehicle integer
---@return table properties
function provider:getProperties(vehicle)
    return self.object.Game.GetVehicleProperties(vehicle)
end

---Apply previously-serialized properties to `vehicle` through `ESX.Game`.
---@param vehicle integer
---@param properties table
function provider:applyProperties(vehicle, properties)
    self.object.Game.SetVehicleProperties(vehicle, properties)
end
