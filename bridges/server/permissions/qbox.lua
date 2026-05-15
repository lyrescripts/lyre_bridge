local provider = LyreBridge.registerProvider("server", "permissions", "qbox", 5)

---Active when the `qbx_core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core")
end

---Cache the qbx_core exports proxy for later calls.
function provider:init()
    self.object = exports.qbx_core
end

---Gather `source`'s job, gang, registered groups and staff permission
---entries as a flat `name -> grade` map.
---@param source integer
---@return table<string, integer>
function provider:getPlayerGroups(source)
    local groups = {}
    local player = self.object:GetPlayer(source)
    local data = player and player.PlayerData

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
        local extra = self.object:GetGroups(source)
        if type(extra) == "table" then
            for name, grade in pairs(extra) do
                if type(name) == "string" then
                    groups[name] = tonumber(grade) or 0
                end
            end
        end
    end

    if type(self.object.GetPermission) == "function" then
        local permission = self.object:GetPermission(source)
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
