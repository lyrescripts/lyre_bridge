local provider = LyreBridge.registerProvider("client", "players", "qbox", 5)

function provider:detect()
    return bridge.core.isStarted("qbx_core")
end

function provider:init()
    self.object = exports.qbx_core
end

function provider:getData()
    return self.object:GetPlayerData()
end

function provider:getIdentifier()
    local data = self.object:GetPlayerData()
    return data.citizenid or data.identifier
end

function provider:getName()
    local charinfo = self.object:GetPlayerData().charinfo or {}
    local first = charinfo.firstname or charinfo.firstName or ""
    local last = charinfo.lastname or charinfo.lastName or ""
    return (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
end

function provider:getJob()
    return self.object:GetPlayerData().job
end

function provider:getGang()
    return self.object:GetPlayerData().gang
end

function provider:isOnJobDuty()
    local job = self.object:GetPlayerData().job
    if not job then return false end
    return job.onduty ~= false
end

function provider:isOnGangDuty()
    local gang = self.object:GetPlayerData().gang
    if not gang then return false end
    return gang.onduty ~= false
end

function provider:getAccount(accountName)
    local key = ({ money = "cash", black_money = "crypto" })[accountName] or accountName or "cash"
    local money = self.object:GetPlayerData().money or {}
    return money[key] or 0
end

function provider:revive()
    TriggerEvent("hospital:client:Revive")
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
    return true
end

function provider:clearDeathStatus()
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
end
