-- Example: plug in a custom vehicle key resource.
--[[
LyreBridge.registerModule("client", "vehicleKeys", function()
    return {
        give = function(plateOrNetId, netId, options)
            local plate = type(plateOrNetId) == "string" and plateOrNetId or options and options.plate
            exports["my_keys"]:GiveTemporaryKey(plate)
            return true
        end,
        remove = function(plate)
            exports["my_keys"]:RemoveKey(plate)
            return true
        end,
    }
end)
]]
