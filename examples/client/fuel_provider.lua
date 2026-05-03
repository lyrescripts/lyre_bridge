-- Example: add a custom fuel provider through a small bridge override.
--[[
CreateThread(function()
    while not bridge do
        Wait(0)
    end

    function bridge:setFuel(vehicleOrNetId, fuel)
        local vehicle = NetworkGetEntityFromNetworkId(vehicleOrNetId) or vehicleOrNetId
        exports["my_fuel"]:SetFuel(vehicle, fuel)
        return true
    end
end)
]]
