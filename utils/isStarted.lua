local startedCache = {}
local providedCache = {}

---Check whether a resource is currently started. Results are cached for up
---to 2.5s and invalidated by resource start/stop events.
---@param resourceName string
---@return boolean
function bridge.core.isStarted(resourceName)
    if type(resourceName) ~= "string" or resourceName == "" then
        return false
    end

    local entry = startedCache[resourceName]
    local now = GetGameTimer()

    if entry and now - entry.at <= 2500 then
        return entry.state == "started"
    end

    local state = GetResourceState(resourceName)
    startedCache[resourceName] = { state = state, at = now }
    return state == "started"
end

---@param resourceName string
---@return string? providerResource Name of the started resource declaring the provide, or nil.
local function findProvider(resourceName)
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resource = GetResourceByFindIndex(i)
        if resource and GetResourceState(resource) == "started" then
            local numProvides = GetNumResourceMetadata(resource, "provide") or 0
            for j = 0, numProvides - 1 do
                if GetResourceMetadata(resource, "provide", j) == resourceName then
                    return resource
                end
            end
        end
    end
    return nil
end

---Whether `resourceName` is directly started OR provided by another started
---resource through a `provide "<name>"` manifest entry. Use this when you
---care about the surface being callable (e.g. `exports.ox_target:...`)
---rather than the exact resource being installed.
---@param resourceName string
---@return boolean
function bridge.core.isAvailable(resourceName)
    if type(resourceName) ~= "string" or resourceName == "" then
        return false
    end

    if bridge.core.isStarted(resourceName) then
        return true
    end

    local entry = providedCache[resourceName]
    local now = GetGameTimer()

    if entry and now - entry.at <= 2500 then
        return entry.providedBy ~= nil
    end

    local providedBy = findProvider(resourceName)
    providedCache[resourceName] = { providedBy = providedBy, at = now }
    return providedBy ~= nil
end

local function invalidate(rn)
    startedCache[rn] = nil
    providedCache = {}
end

AddEventHandler("onResourceStart", invalidate)
AddEventHandler("onResourceStop", invalidate)
AddEventHandler("onClientResourceStart", invalidate)
AddEventHandler("onClientResourceStop", invalidate)
