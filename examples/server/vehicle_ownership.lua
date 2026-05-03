-- Example: share vehicle ownership checks across garage-like resources.
--[[
LyreBridge.registerModule("server", "vehicleOwnership", function()
    return {
        isOwner = function(identifier, plate)
            local row = MySQL.single.await("SELECT owner FROM owned_vehicles WHERE plate = ?", { plate })
            return row and row.owner == identifier or false
        end,
    }
end)
]]
