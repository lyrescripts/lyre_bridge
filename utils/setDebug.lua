---Toggle info/debug logging for the invoking resource at runtime.
---@param enabled boolean
function bridge.core.setDebug(enabled)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    LyreBridge.config.debug[resourceName] = enabled == true
end
