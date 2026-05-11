local provider = LyreBridge.registerProvider("client", "players", "qbcore", 20)

function provider:detect()
    return bridge.core:isStarted("qb-core")
end

function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

function provider:getData()
    return self.object.Functions.GetPlayerData()
end

function provider:getIdentifier()
    return self.object.Functions.GetPlayerData().citizenid
end

function provider:getName()
    local charinfo = self.object.Functions.GetPlayerData().charinfo or {}
    return ((charinfo.firstname or "") .. " " .. (charinfo.lastname or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

function provider:getJob()
    return self.object.Functions.GetPlayerData().job
end

function provider:getGang()
    return self.object.Functions.GetPlayerData().gang
end

function provider:isOnJobDuty()
    local job = self.object.Functions.GetPlayerData().job
    if not job then return false end
    return job.onduty ~= false
end

function provider:isOnGangDuty()
    local gang = self.object.Functions.GetPlayerData().gang
    if not gang then return false end
    return gang.onduty ~= false
end

function provider:getAccount(accountName)
    local key = ({ money = "cash", black_money = "crypto" })[accountName] or accountName or "cash"
    local money = self.object.Functions.GetPlayerData().money or {}
    return money[key] or 0
end

function provider:revive()
    if bridge.core:isStarted("qb-ambulancejob") then
        pcall(function()
            exports["qb-ambulancejob"]:RevivePlayer()
        end)
    end
    TriggerEvent("hospital:client:Revive")
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
    return true
end

function provider:clearDeathStatus()
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
end
