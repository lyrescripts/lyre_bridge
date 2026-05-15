local provider = LyreBridge.registerProvider("client", "vehicles", "default", 100)

---Always active; the default client-side vehicle helpers are the universal fallback.
---@return boolean
function provider:detect()
    return true
end

---Serialize the visual properties of `vehicle`.
---@param vehicle integer
---@return table? properties `nil` when no supported framework was available.
function provider:getProperties(vehicle)
    if bridge.core.isStarted("ox_lib") and lib and type(lib.getVehicleProperties) == "function" then
        return lib.getVehicleProperties(vehicle)
    end

    if bridge.core.isStarted("es_extended") then
        local ESX = exports["es_extended"]:getSharedObject()
        if ESX and ESX.Game and ESX.Game.GetVehicleProperties then
            return ESX.Game.GetVehicleProperties(vehicle)
        end
    end

    return nil
end

---Apply previously-serialized properties to `vehicle`.
---@param vehicle integer
---@param properties table
---@return boolean applied false when no supported framework was available.
function provider:applyProperties(vehicle, properties)
    if not properties then return false end

    if bridge.core.isStarted("ox_lib") and lib and type(lib.setVehicleProperties) == "function" then
        lib.setVehicleProperties(vehicle, properties)
        return true
    end

    if bridge.core.isStarted("es_extended") then
        local ESX = exports["es_extended"]:getSharedObject()
        if ESX and ESX.Game and ESX.Game.SetVehicleProperties then
            ESX.Game.SetVehicleProperties(vehicle, properties)
            return true
        end
    end

    return false
end
