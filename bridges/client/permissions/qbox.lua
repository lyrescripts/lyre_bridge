local provider = LyreBridge.registerProvider("client", "permissions", "qbox", 5)

---Active when the `qbx_core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core")
end

---Cache the qbx_core exports proxy for later calls.
function provider:init()
    self.object = exports.qbx_core
end

---Gather the local player's job, gang and registered groups as a flat
---`name -> grade` map.
---@return table<string, integer>
function provider:getPlayerGroups()
    local groups = {}

    local data = self.object:GetPlayerData()
    if data then
        local job = data.job
        if job and type(job.name) == "string" then
            groups[job.name] = tonumber(job.grade and job.grade.level) or 0
        end

        local gang = data.gang
        if gang and type(gang.name) == "string" then
            groups[gang.name] = tonumber(gang.grade and gang.grade.level) or 0
        end
    end

    if type(self.object.GetGroups) == "function" then
        local extra = self.object:GetGroups()
        if type(extra) == "table" then
            for name, grade in pairs(extra) do
                if type(name) == "string" then
                    groups[name] = tonumber(grade) or 0
                end
            end
        end
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
