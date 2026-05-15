local cache = {}

---Check whether a resource is currently started. Results are cached for up to
---2.5s and invalidated by resource start/stop events.
---@param resourceName string
---@return boolean
function bridge.core.isStarted(resourceName)
    if type(resourceName) ~= "string" or resourceName == "" then
        return false
    end

    local entry = cache[resourceName]
    local now = GetGameTimer()

    if entry and now - entry.at <= 2500 then
        return entry.state == "started"
    end

    local state = GetResourceState(resourceName)
    cache[resourceName] = { state = state, at = now }
    return state == "started"
end

AddEventHandler("onResourceStart", function(rn) cache[rn] = nil end)
AddEventHandler("onResourceStop", function(rn) cache[rn] = nil end)
AddEventHandler("onClientResourceStart", function(rn) cache[rn] = nil end)
AddEventHandler("onClientResourceStop", function(rn) cache[rn] = nil end)
