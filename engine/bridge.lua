local CURRENT_SIDE = IsDuplicityVersion() and "server" or "client"
local LIFECYCLE = { detect = true, init = true }

---@type Bridge
bridge = {
    core = {},
    custom = {},
    config = {},
}

local built = false

---Build a thin dispatcher that lazily resolves the active provider for the
---given module and forwards the call to its same-named method.
---@param side BridgeSide
---@param moduleName string
---@param methodName string
---@return fun(...): any
local function makeWrapper(side, moduleName, methodName)
    return function(...)
        local provider = LyreBridge.resolveProvider(side, moduleName)
        if not provider then
            return
        end
        local fn = provider[methodName]
        if type(fn) ~= "function" then
            return
        end
        return fn(provider, ...)
    end
end

---Populate `bridge[moduleName]` for every module registered on `side` by
---taking the union of the public method names across every provider.
---@param side BridgeSide
local function discoverSide(side)
    local buckets = LyreBridge.providers[side]
    if not buckets then
        return
    end
    for moduleName, bucket in pairs(buckets) do
        if not bridge[moduleName] then
            bridge[moduleName] = {}
        end
        for _, provider in ipairs(bucket) do
            for methodName, fn in pairs(provider) do
                if type(fn) == "function"
                    and not LIFECYCLE[methodName]
                    and not methodName:find("^__")
                    and bridge[moduleName][methodName] == nil
                then
                    bridge[moduleName][methodName] = makeWrapper(side, moduleName, methodName)
                end
            end
        end
    end
end

---Walk every registered provider on the current side (plus the shared bucket)
---and generate a flat wrapper for each public method. Idempotent — repeat
---calls are a no-op.
---@return Bridge
function LyreBridge.buildBridge()
    if built then
        return bridge
    end
    built = true
    discoverSide(CURRENT_SIDE)
    discoverSide("shared")
    return bridge
end

---Export consumed by `@lyre_bridge/imports.lua` from external resources.
exports("getBridge", function()
    return LyreBridge.buildBridge()
end)
