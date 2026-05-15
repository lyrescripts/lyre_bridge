local provider = LyreBridge.registerProvider("client", "permissions", "qbcore", 20)

---Active when the `qb-core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Gather the local player's job and gang as a flat `name -> grade` map.
---@return table<string, integer>
function provider:getPlayerGroups()
    local groups = {}
    local data = self.object.Functions.GetPlayerData()
    if not data then return groups end

    local job = data.job
    if job and type(job.name) == "string" then
        groups[job.name] = tonumber(job.grade and job.grade.level) or 0
    end

    local gang = data.gang
    if gang and type(gang.name) == "string" then
        groups[gang.name] = tonumber(gang.grade and gang.grade.level) or 0
    end

    return groups
end

---Whether the local player belongs to any of the required `groups`.
---Accepts a bare name, an array of names (any match) or a dict
---`name -> minGrade`.
---@param groups BridgeGroups
---@return boolean
function provider:hasGroups(groups)
    if groups == nil then return true end

    local playerGroups = self:getPlayerGroups() or {}

    if type(groups) == "string" then
        return playerGroups[groups] ~= nil
    end

    if type(groups) ~= "table" then return false end

    if #groups > 0 then
        for i = 1, #groups do
            if playerGroups[groups[i]] ~= nil then return true end
        end
        return false
    end

    for name, minGrade in pairs(groups) do
        local grade = playerGroups[name]
        if grade ~= nil and grade >= (tonumber(minGrade) or 0) then
            return true
        end
    end
    return false
end
