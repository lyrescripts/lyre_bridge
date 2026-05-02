-- Example: extend framework object discovery without editing imports/server/framework.lua.
--[[
LyreBridge.registerModule("server", "framework", function()
    return {
        getESX = function()
            return exports["es_extended"]:getSharedObject()
        end,
        getQBCore = function()
            return exports["qb-core"]:GetCoreObject()
        end,
        getQBox = function()
            return exports["qbx_core"]
        end,
    }
end)
]]
