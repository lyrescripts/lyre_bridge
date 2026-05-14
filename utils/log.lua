function bridge.core.log(logType, msg, invoker)
    logType = logType and string.lower(logType) or "info"

    if logType == "debug" and not LyreBridge.debug then
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

    print("^5(^2" .. string.upper(invoker or GetInvokingResource() or GetCurrentResourceName()) .. "^5) ^4- " .. prefix .. msg)
end
