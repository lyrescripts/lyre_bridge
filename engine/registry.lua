LyreBridge = LyreBridge or {}

LyreBridge.providers = { client = {}, server = {}, shared = {} }

function LyreBridge.registerProvider(side, moduleName, name, priority)
    assert(side == "client" or side == "server" or side == "shared",
        "registerProvider: side must be client, server or shared")
    assert(type(moduleName) == "string" and moduleName ~= "",
        "registerProvider: module is required")
    assert(type(name) == "string" and name ~= "",
        "registerProvider: name is required")

    local provider = {
        __side = side,
        __module = moduleName,
        __name = name,
        __priority = priority or 100,
    }

    local bucket = LyreBridge.providers[side][moduleName]
    if not bucket then
        bucket = {}
        LyreBridge.providers[side][moduleName] = bucket
    end

    bucket[#bucket + 1] = provider
    table.sort(bucket, function(left, right)
        return (left.__priority or 100) < (right.__priority or 100)
    end)

    return provider
end
