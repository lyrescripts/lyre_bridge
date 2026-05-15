---Toggle bridge debug logging at runtime.
---@param enabled boolean
function bridge.core.setDebug(enabled)
    LyreBridge.debug = enabled == true
end
