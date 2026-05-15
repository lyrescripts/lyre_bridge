local provider = LyreBridge.registerProvider("server", "permissions", "esx", 10)

---Active when the `es_extended` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Gather `source`'s job and admin group as a flat `name -> grade` map.
---@param source integer
---@return table<string, integer>
function provider:getPlayerGroups(source)
    local groups = {}
    local xPlayer = self.object.GetPlayerFromId(source)
    if not xPlayer then return groups end

    local job = xPlayer.getJob and xPlayer.getJob()
    if job and type(job.name) == "string" then
        groups[job.name] = tonumber(job.grade) or 0
    end

    local groupName = xPlayer.getGroup and xPlayer.getGroup()
    if type(groupName) == "string" and groupName ~= "" then
        groups[groupName] = 0
    end

    return groups
end

---Whether `source` is allowed to use the ACE permission `ace`. Honors
---`group.<ace>` and `command.<ace>` variants.
---@param source integer
---@param ace string
---@return boolean
function provider:hasAce(source, ace)
    if type(ace) ~= "string" or ace == "" then return false end
    return IsPlayerAceAllowed(source, ace)
        or IsPlayerAceAllowed(source, "group." .. ace)
        or IsPlayerAceAllowed(source, "command." .. ace)
end

---Whether `source` belongs to any of the required `groups`. Accepts a
---bare name, an array of names (any match) or a dict `name -> minGrade`.
---Falls back to ACE checks when no framework group matches.
---@param source integer
---@param groups BridgeGroups
---@return boolean
function provider:hasGroups(source, groups)
    if groups == nil then return true end

    local playerGroups = self:getPlayerGroups(source) or {}

    if type(groups) == "string" then
        return playerGroups[groups] ~= nil or self:hasAce(source, groups)
    end

    if type(groups) ~= "table" then return false end

    if #groups > 0 then
        for i = 1, #groups do
            local name = groups[i]
            if playerGroups[name] ~= nil or self:hasAce(source, name) then
                return true
            end
        end
        return false
    end

    for name, minGrade in pairs(groups) do
        local grade = playerGroups[name]
        if grade ~= nil and grade >= (tonumber(minGrade) or 0) then
            return true
        end
        if self:hasAce(source, name) then return true end
    end
    return false
end
