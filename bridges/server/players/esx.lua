local provider = LyreBridge.registerProvider("server", "players", "esx", 10)

function provider:detect()
    return bridge.core:isStarted("es_extended")
end

function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

function provider:getPlayerFromId(playerId)
    local xPlayer = self.object.GetPlayerFromId(playerId)
    if not xPlayer then
        return false
    end

    local player = {
        source = xPlayer.source,
        raw = xPlayer,
    }

    player.getIdentifier = function()
        return xPlayer.identifier
    end

    player.getName = function()
        return xPlayer.getName()
    end

    player.getFirstName = function()
        return xPlayer.get and xPlayer.get("firstName") or ""
    end

    player.getLastName = function()
        return xPlayer.get and xPlayer.get("lastName") or ""
    end

    player.getJob = function()
        return xPlayer.getJob()
    end

    player.getAccount = function(account)
        return xPlayer.getAccount(account).money
    end

    player.addAccountMoney = function(account, amount)
        xPlayer.addAccountMoney(account, amount)
    end

    player.removeAccountMoney = function(account, amount)
        xPlayer.removeAccountMoney(account, amount)
    end

    player.showNotification = function(message)
        xPlayer.showNotification(message)
    end

    player.addItem = function(itemName, count, metadata)
        xPlayer.addInventoryItem(itemName, count, metadata)
    end

    player.removeItem = function(itemName, count)
        xPlayer.removeInventoryItem(itemName, count)
    end

    player.getItemCount = function(itemName)
        local item = xPlayer.getInventoryItem(itemName)
        return item and item.count or 0
    end

    player.hasLicense = function(licenseType)
        local result = false
        TriggerEvent("esx_license:checkLicense", xPlayer.source, licenseType, function(has)
            result = has == true
        end)
        return result
    end

    player.grantLicense = function(licenseType)
        TriggerEvent("esx_license:addLicense", xPlayer.source, licenseType)
        return true
    end

    player.getAdminRank = function()
        return xPlayer.getGroup and xPlayer.getGroup() or "user"
    end

    return player
end

function provider:getPlayerFromIdentifier(identifier)
    local source = self:getIdFromIdentifier(identifier)
    if not source then
        return false
    end
    return self:getPlayerFromId(source)
end

function provider:getIdFromIdentifier(identifier)
    if not identifier then
        return false
    end

    local xPlayer = self.object.GetPlayerFromIdentifier(identifier)
    if not xPlayer then
        return false
    end

    return xPlayer.source
end

function provider:getOnlinePlayers()
    local players = {}
    for _, xPlayer in pairs(self.object.GetExtendedPlayers()) do
        players[#players + 1] = self:getPlayerFromId(xPlayer.source)
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
    for _, xPlayer in pairs(self.object.GetExtendedPlayers()) do
        local job = xPlayer.job
        if job and jobMap[job.name] then
            if not onDutyOnly or (job.onDuty ~= false and job.onduty ~= false) then
                players[#players + 1] = self:getPlayerFromId(xPlayer.source)
            end
        end
    end
    return players
end

function provider:getPlayersInZone(coords, radius, options)
    options = options or {}
    local players = {}

    for _, xPlayer in pairs(self.object.GetExtendedPlayers()) do
        if not options.exceptions or not options.exceptions[xPlayer.source] then
            local ped = GetPlayerPed(xPlayer.source)
            local playerCoords = GetEntityCoords(ped)
            if #(coords - playerCoords) <= radius then
                if options.includeDead or GetEntityHealth(ped) > 0 then
                    players[#players + 1] = self:getPlayerFromId(xPlayer.source)
                end
            end
        end
    end

    return players
end

function provider:revive(source)
    if not source then return false end
    TriggerClientEvent("esx_ambulancejob:revive", source)
    return true
end

function provider:clearDeathStatus(source)
    -- ESX ambulance scripts keep death status client-side; nothing to clear server-side.
    return true
end

function provider:updateOfflinePlayerAccount(identifier, account, amount)
    if not identifier or not account or not amount then
        return false
    end

    local row = MySQL.single.await("SELECT accounts FROM users WHERE identifier = ?", { identifier })
    if not row then
        return false
    end

    local accounts = json.decode(row.accounts) or {}
    if not accounts[account] then
        return false
    end

    accounts[account] = accounts[account] + amount

    local affected = MySQL.update.await(
        "UPDATE users SET accounts = ? WHERE identifier = ?",
        { json.encode(accounts), identifier }
    )

    return (affected or 0) > 0
end
