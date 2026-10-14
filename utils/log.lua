---Emit a console message, filtering info/debug logs by resource configuration.
---@param logType? BridgeLogType Defaults to info.
---@param msg any Message converted to text.
---@param invoker? string Defaults to the invoking resource.
---@return void
function bridge.core.log(logType, msg, invoker)
    logType = type(logType) == "string" and string.lower(logType) or "info"
    if logType == "warn" then
        logType = "warning"
    end

    local resourceName = invoker or GetInvokingResource() or GetCurrentResourceName()
    if logType ~= "error" and logType ~= "warning"
        and not LyreBridge.resolveDebug(resourceName) then
        return
    end

    local prefix
    if logType == "error" then
        prefix = "^1[ERROR]^0 "
    elseif logType == "warning" then
        prefix = "^3[WARNING]^0 "
    elseif logType == "debug" then
        prefix = "^6[DEBUG]^0 "
    else
        prefix = "^2[INFO]^0 "
    end

    print("^5(^2" .. string.upper(resourceName) .. "^5) ^4- " .. prefix .. tostring(msg))
end
