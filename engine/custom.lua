LyreBridge.customFunctions = {}

function LyreBridge.registerCustomResourceFunction(resourceName, fnName, fn)
    assert(type(resourceName) == "string" and resourceName ~= "",
        "registerCustomResourceFunction: resource name is required")
    assert(type(fnName) == "string" and fnName ~= "",
        "registerCustomResourceFunction: function name is required")
    assert(type(fn) == "function",
        "registerCustomResourceFunction: function is required")

    LyreBridge.customFunctions[resourceName] = LyreBridge.customFunctions[resourceName] or {}
    LyreBridge.customFunctions[resourceName][fnName] = fn
end

function bridge.custom.register(fnName, fn)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    LyreBridge.registerCustomResourceFunction(resource, fnName, fn)
end

function bridge.custom.call(fnName, ...)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local fns = LyreBridge.customFunctions[resource]
    local fn = fns and fns[fnName]
    if fn then
        return fn(...)
    end
end

function bridge.custom.has(fnName)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local fns = LyreBridge.customFunctions[resource]
    return fns and fns[fnName] ~= nil or false
end
