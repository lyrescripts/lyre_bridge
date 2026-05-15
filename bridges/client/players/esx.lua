local provider = LyreBridge.registerProvider("client", "players", "esx", 10)

---Active when the `es_extended` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Raw ESX player-data table.
---@return table
function provider:getData()
    return self.object.GetPlayerData()
end

---Persistent identifier of the local player.
---@return string
function provider:getIdentifier()
    return self.object.GetPlayerData().identifier
end

---Display name of the local player.
---@return string
function provider:getName()
    local data = self.object.GetPlayerData()
    return data.firstName and data.lastName
        and ((data.firstName or "") .. " " .. (data.lastName or ""))
        or GetPlayerName(PlayerId())
end

---Current job name. Returns `"unemployed"` (or whatever ESX configured)
---when no job is set.
---@return string
function provider:getJob()
    local job = self.object.GetPlayerData().job
    return job and job.name or "unemployed"
end

---Current job grade level.
---@return integer
function provider:getJobRank()
    local job = self.object.GetPlayerData().job
    return tonumber(job and job.grade) or 0
end

---ESX has no native gang concept; returns a stable placeholder so
---callers can iterate without nil checks.
---@return "ballas"
function provider:getGang()
    return "ballas"
end

---ESX has no native gang grade.
---@return 0
function provider:getGangRank()
    return 0
end

---Whether the local player is on job duty.
---@return boolean
function provider:isOnJobDuty()
    local job = self.object.GetPlayerData().job
    if not job then return false end
    if job.onDuty ~= nil then return job.onDuty end
    return true
end

---Whether the local player is on gang duty; ESX has no gangs.
---@return boolean
function provider:isOnGangDuty()
    return false
end

---Current balance of the requested account.
---@param accountName BridgeAccount
---@return integer
function provider:getAccount(accountName)
    local accounts = self.object.GetPlayerData().accounts or {}
    for _, account in ipairs(accounts) do
        if account.name == accountName then
            return account.money or 0
        end
    end
    return 0
end

---Revive the local player via the ESX ambulance script.
---@return boolean
function provider:revive()
    if bridge.core.isStarted("esx_ambulancejob") then
        TriggerEvent("esx_ambulancejob:revive")
        TriggerServerEvent("esx_ambulancejob:setDeathStatus", false)
        return true
    end
    return false
end

---Clear the framework-tracked death flag.
function provider:clearDeathStatus()
    if bridge.core.isStarted("esx_ambulancejob") then
        TriggerServerEvent("esx_ambulancejob:setDeathStatus", false)
    end
end
