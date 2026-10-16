---Toggle info/debug logging for the invoking resource at runtime.
---@param enabled boolean
---@return void
function bridge.core.setDebug(enabled)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    LyreBridge.resourceDebug[resourceName] = enabled == true
end
