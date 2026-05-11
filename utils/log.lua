function bridge.core:log(type, msg, invoker)
    type = type and string.lower(type) or "info"

    if type == "debug" and not LyreBridge.debug then
        return
    end

    local prefix
    if type == "error" then
        prefix = "^1[ERROR]^0 "
    elseif type == "warning" then
        prefix = "^3[WARNING]^0 "
    elseif type == "debug" then
        prefix = "^6[DEBUG]^0 "
    else
        prefix = "^2[INFO]^0 "
    end

    print("^5(^2" .. string.upper(invoker or GetCurrentResourceName()) .. "^5) ^4- " .. prefix .. msg)
end
