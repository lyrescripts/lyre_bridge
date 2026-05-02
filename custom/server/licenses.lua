-- Example: centralize license checks for school resources.
--[[
LyreBridge.registerModule("server", "licenses", function()
    return {
        has = function(source, license, cb)
            TriggerEvent("esx_license:checkLicense", source, license, cb)
        end,
        grant = function(source, license)
            TriggerEvent("esx_license:addLicense", source, license)
            return true
        end,
    }
end)
]]
