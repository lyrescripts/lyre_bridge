local provider = LyreBridge.registerProvider("server", "permissions", "qbcore", 20)

---Active when the `qb-core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Gather `source`'s job, gang and staff permission entries as a flat
---`name -> grade` map. Staff entries are read from
---`QBCore.Functions.GetPermission` which returns either a table of
---`{ name = true }` (modern versions) or a single string.
---@param source integer
---@return table<string, integer>
function provider:getPlayerGroups(source)
    local groups = {}
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return groups end

    local data = qbPlayer.PlayerData or {}
    local job = data.job
    if job and type(job.name) == "string" then
        groups[job.name] = tonumber(job.grade and job.grade.level) or 0
    end

    local gang = data.gang
    if gang and type(gang.name) == "string" then
        groups[gang.name] = tonumber(gang.grade and gang.grade.level) or 0
    end

    if type(self.object.Functions.GetPermission) == "function" then
        local permission = self.object.Functions.GetPermission(source)
        if type(permission) == "table" then
            for permName in pairs(permission) do
                if type(permName) == "string" and permName ~= "" then
                    groups[permName] = 0
                end
            end
        elseif type(permission) == "string" and permission ~= "" then
            groups[permission] = 0
        end
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
