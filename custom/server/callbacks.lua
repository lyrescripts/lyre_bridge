-- Example: expose a callback helper for a custom callback resource.
--[[
LyreBridge.registerModule("server", "callbacks", function()
    return {
        register = function(name, handler)
            exports["my_callbacks"]:Register(name, handler)
            return true
        end,
    }
end)
]]
