local provider = LyreBridge.registerProvider("client", "players", "esx", 10)

function provider:detect()
    return bridge.core:isStarted("es_extended")
end

function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

function provider:getData()
    return self.object.GetPlayerData()
end

function provider:getIdentifier()
    return self.object.GetPlayerData().identifier
end

function provider:getName()
    local data = self.object.GetPlayerData()
    return data.firstName and data.lastName
        and ((data.firstName or "") .. " " .. (data.lastName or ""))
        or GetPlayerName(PlayerId())
end

function provider:getJob()
    local job = self.object.GetPlayerData().job
    if not job or job.name == "unemployed" then return nil end
    return job
end

function provider:getGang()
    return nil
end

function provider:isOnJobDuty()
    local job = self.object.GetPlayerData().job
    if not job then return false end
    if job.onDuty ~= nil then return job.onDuty end
    return true
end

function provider:isOnGangDuty()
    return false
end

function provider:getAccount(accountName)
    local accounts = self.object.GetPlayerData().accounts or {}
    for _, account in ipairs(accounts) do
        if account.name == accountName then
            return account.money or 0
        end
    end
    return 0
end

function provider:revive()
    if bridge.core:isStarted("esx_ambulancejob") then
        TriggerEvent("esx_ambulancejob:revive")
        TriggerServerEvent("esx_ambulancejob:setDeathStatus", false)
        return true
    end
    return false
end

function provider:clearDeathStatus()
    if bridge.core:isStarted("esx_ambulancejob") then
        TriggerServerEvent("esx_ambulancejob:setDeathStatus", false)
    end
end
