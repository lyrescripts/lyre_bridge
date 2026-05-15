local provider = LyreBridge.registerProvider("server", "players", "qbcore", 20)

---Active when the `qb-core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Resolve a player wrapper from their server id.
---@param playerId integer
---@return BridgePlayer | false player
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
        return qbPlayer.Functions.AddMoney(key, amount, "") ~= false
    end

    player.removeAccountMoney = function(account, amount)
        if player.getAccount(account) < amount then return false end
        local key = ({ money = "cash", black_money = "crypto" })[account] or account or "cash"
        return qbPlayer.Functions.RemoveMoney(key, amount, "") ~= false
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

---Resolve a player wrapper from their persistent citizen id.
---@param identifier string
---@return BridgePlayer | false
function provider:getPlayerFromIdentifier(identifier)
    local qbPlayer = self.object.Functions.GetPlayerByCitizenId(identifier)
    if not qbPlayer then
        return false
    end
    return self:getPlayerFromId(qbPlayer.PlayerData.source)
end

---Look up the server id currently bound to a citizen id.
---@param identifier string
---@return integer | false
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

---List every player currently connected.
---@return BridgePlayer[]
function provider:getOnlinePlayers()
    local players = {}
    for _, source in ipairs(self.object.Functions.GetPlayers()) do
        players[#players + 1] = self:getPlayerFromId(source)
    end
    return players
end

---List online players whose job matches the requested name(s).
---@param jobs string | string[] Single job name or an array of job names.
---@param onDutyOnly? boolean When true, skip players currently off-duty.
---@return BridgePlayer[]
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

---List players within `radius` of `coords`.
---@param coords vector3
---@param radius number
---@param options? { exceptions?: table<integer, boolean>, includeDead?: boolean } `exceptions` excludes sources; `includeDead` keeps players with 0 HP.
---@return BridgePlayer[]
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

---Revive a downed player. Dispatches the `lyre_bridge:players:revive`
---relay to the target so the client-side revive (native resurrect +
---hospital metadata cleanup) runs in one call.
---@param source integer
---@return boolean
function provider:revive(source)
    if not source then return false end
    TriggerClientEvent("lyre_bridge:players:revive", source)
    return true
end

---Clear the QB-tracked death and last-stand metadata.
---@param source integer
---@return boolean
function provider:clearDeathStatus(source)
    local qbPlayer = self.object.Functions.GetPlayer(source)
    if not qbPlayer then return false end
    qbPlayer.Functions.SetMetaData("isdead", false)
    qbPlayer.Functions.SetMetaData("inlaststand", false)
    return true
end

---Add `amount` to an offline player's account balance and persist it.
---@param identifier string
---@param account BridgeAccount
---@param amount integer Signed; pass a negative number to deduct.
---@return boolean
function provider:updateOfflinePlayerAccount(identifier, account, amount)
    if not identifier or not account or not amount then
        return false
    end

    local row = bridge.mysql.single("SELECT money FROM players WHERE citizenid = ?", { identifier })
    if not row then
        return false
    end

    local key = ({ money = "cash", black_money = "crypto" })[account] or account or "cash"
    local money = json.decode(row.money) or {}
    money[key] = (money[key] or 0) + amount

    local affected = bridge.mysql.update(
        "UPDATE players SET money = ? WHERE citizenid = ?",
        { json.encode(money), identifier }
    )

    return (affected or 0) > 0
end
