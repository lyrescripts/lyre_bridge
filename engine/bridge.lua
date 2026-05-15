local CURRENT_SIDE = IsDuplicityVersion() and "server" or "client"
local LIFECYCLE = { detect = true, init = true }

bridge = {
    core = {},
    custom = {},
    config = {},
}

local built = false

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

function LyreBridge.buildBridge()
    if built then
        return bridge
    end
    built = true
    discoverSide(CURRENT_SIDE)
    discoverSide("shared")
    return bridge
end

exports("getBridge", function()
    return LyreBridge.buildBridge()
end)
