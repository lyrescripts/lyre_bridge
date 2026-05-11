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
