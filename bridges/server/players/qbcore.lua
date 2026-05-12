local provider = LyreBridge.registerProvider("server", "players", "qbcore", 20)

function provider:detect()
    return bridge.core:isStarted("qb-core")
end

function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

function provider:getPlayerFromId(playerId)
    local qbPlayer = self.object.Functions.GetPlayer(playerId)
    if not qbPlayer then
        return false
    end

    local data = qbPlayer.PlayerData
    local charinfo = data.charinfo or {}

    local player = {
        source = data.source,
        raw = qbPlayer,
    }

    player.getIdentifier = function()
        return data.citizenid
    end

    player.getName = function()
        return ((charinfo.firstname or "") .. " " .. (charinfo.lastname or "")):gsub("^%s+", ""):gsub("%s+$", "")
    end

    player.getFirstName = function()
        return charinfo.firstname or ""
    end

    player.getLastName = function()
        return charinfo.lastname or ""
    end

    player.getJob = function()
        return data.job
    end

    player.getAccount = function(account)
        local key = ({ money = "cash", black_money = "crypto" })[account] or account or "cash"
        return data.money and data.money[key] or 0
    end

    player.addAccountMoney = function(account, amount)
        local key = ({ money = "cash", black_money = "crypto" })[account] or account or "cash"
        qbPlayer.Functions.AddMoney(key, amount, "")
    end

    player.removeAccountMoney = function(account, amount)
        local key = ({ money = "cash", black_money = "crypto" })[account] or account or "cash"
        qbPlayer.Functions.RemoveMoney(key, amount, "")
    end

    player.showNotification = function(message, notificationType, duration)
        TriggerClientEvent("QBCore:Notify", data.source, message, notificationType or "primary", duration or 5000)
    end

    player.addItem = function(itemName, count, metadata)
        qbPlayer.Functions.AddItem(itemName, count, nil, metadata)
    end

    player.removeItem = function(itemName, count)
        qbPlayer.Functions.RemoveItem(itemName, count)
    end

    player.getItemCount = function(itemName)
        local item = qbPlayer.Functions.GetItemByName(itemName)
        return item and item.amount or 0
    end

    player.hasLicense = function(licenseType)
        local licenses = data.metadata and data.metadata.licences or {}
        return licenses[licenseType] == true
    end

    player.grantLicense = function(licenseType)
        local licenses = data.metadata and data.metadata.licences or {}
        licenses[licenseType] = true
        qbPlayer.Functions.SetMetaData("licences", licenses)
        return true
    end

    player.getAdminRank = function()
        return self.object.Functions.GetPermission and self.object.Functions.GetPermission(data.source) or "user"
    end

    return player
end

function provider:getPlayerFromIdentifier(identifier)
    local qbPlayer = self.object.Functions.GetPlayerByCitizenId(identifier)
    if not qbPlayer then
        return false
    end
    return self:getPlayerFromId(qbPlayer.PlayerData.source)
end

function provider:getIdFromIdentifier(identifier)
    if not identifier then
        return false
    end

    local qbPlayer = self.object.Functions.GetPlayerByCitizenId(identifier)
    if not qbPlayer then
        return false
    end

    return qbPlayer.PlayerData.source
end

function provider:getOnlinePlayers()
    local players = {}
    for _, source in ipairs(self.object.Functions.GetPlayers()) do
        players[#players + 1] = self:getPlayerFromId(source)
    end
    return players
end

function provider:getOnlinePlayersByJob(jobs, onDutyOnly)
    local jobMap = {}
    if type(jobs) == "string" then
        jobMap[jobs] = true
    elseif type(jobs) == "table" then
        for _, jobName in ipairs(jobs) do
            jobMap[jobName] = true
        end
    end

    local players = {}
    for _, source in ipairs(self.object.Functions.GetPlayers()) do
        local qbPlayer = self.object.Functions.GetPlayer(source)
        local job = qbPlayer and qbPlayer.PlayerData.job
        if job and jobMap[job.name] then
            if not onDutyOnly or job.onduty ~= false then
                players[#players + 1] = self:getPlayerFromId(source)
            end
        end
    end
    return players
end

function provider:getPlayersInZone(coords, radius, options)
    options = options or {}
    local players = {}

    for _, source in ipairs(self.object.Functions.GetPlayers()) do
        if not options.exceptions or not options.exceptions[source] then
            local ped = GetPlayerPed(source)
            local playerCoords = GetEntityCoords(ped)
            if #(coords - playerCoords) <= radius then
                if options.includeDead or GetEntityHealth(ped) > 0 then
                    players[#players + 1] = self:getPlayerFromId(source)
                end
            end
        end
    end

    return players
end

function provider:revive(source)
    if not source then return false end
    TriggerClientEvent("hospital:client:Revive", source)
    return true
end

function provider:clearDeathStatus(source)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    qbPlayer.Functions.SetMetaData("isdead", false)
    qbPlayer.Functions.SetMetaData("inlaststand", false)
    return true
end

function provider:updateOfflinePlayerAccount(identifier, account, amount)
    if not identifier or not account or not amount then
        return false
    end

    local row = bridge.mysql:single("SELECT money FROM players WHERE citizenid = ?", { identifier })
    if not row then
        return false
    end

    local key = ({ money = "cash", black_money = "crypto" })[account] or account or "cash"
    local money = json.decode(row.money) or {}
    money[key] = (money[key] or 0) + amount

    local affected = bridge.mysql:update(
        "UPDATE players SET money = ? WHERE citizenid = ?",
        { json.encode(money), identifier }
    )

    return (affected or 0) > 0
end
