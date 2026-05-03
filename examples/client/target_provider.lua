-- Example: register a completely custom target module.
--[[
LyreBridge.registerModule("client", "target", function()
    return {
        addLocalEntity = function(entity, options)
            return exports["my_target"]:AddEntity(entity, options)
        end,
        removeEntity = function(entity, optionNames)
            return exports["my_target"]:RemoveEntity(entity, optionNames)
        end,
        addSphereZone = function(options)
            return exports["my_target"]:AddSphere(options)
        end,
        removeZone = function(id)
            return exports["my_target"]:RemoveZone(id)
        end,
    }
end)
]]
