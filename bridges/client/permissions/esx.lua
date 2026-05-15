local provider = LyreBridge.registerProvider("client", "permissions", "esx", 10)

---Active when the `es_extended` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Gather the local player's job and admin group as a flat `name -> grade`
---map.
---@return table<string, integer>
function provider:getPlayerGroups()
    local groups = {}
    local data = self.object.GetPlayerData and self.object.GetPlayerData() or nil
    if not data then return groups end

    local job = data.job
    if job and type(job.name) == "string" then
        groups[job.name] = tonumber(job.grade) or 0
    end

    if type(data.group) == "string" and data.group ~= "" then
        groups[data.group] = 0
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
