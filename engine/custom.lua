LyreBridge.customFunctions = {}

---Register a custom function for a specific resource. Functions are keyed by
---resource name and look-up is per-caller; see `bridge.custom.call`.
---@param resourceName string
---@param fnName string
---@param fn function
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

---Register a custom function for the invoking resource.
---@param fnName string
---@param fn function
function bridge.custom.register(fnName, fn)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    LyreBridge.registerCustomResourceFunction(resource, fnName, fn)
end

---Call a custom function previously registered for the invoking resource.
---Silently returns `nil` when the function is not registered.
---@param fnName string
---@return any
function bridge.custom.call(fnName, ...)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local fns = LyreBridge.customFunctions[resource]
    local fn = fns and fns[fnName]
    if fn then
        return fn(...)
    end
end

---Check whether a custom function is registered for the invoking resource.
---@param fnName string
---@return boolean
function bridge.custom.has(fnName)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local fns = LyreBridge.customFunctions[resource]
    return fns and fns[fnName] ~= nil or false
end
