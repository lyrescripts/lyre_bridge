local provider = LyreBridge.registerProvider("client", "players", "qbcore", 20)

---Active when the `qb-core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Raw QBCore player-data table.
---@return table
function provider:getData()
    return self.object.Functions.GetPlayerData()
end

---Persistent citizen id of the local player.
---@return string
function provider:getIdentifier()
    return self.object.Functions.GetPlayerData().citizenid
end

---Display name of the local player.
---@return string
function provider:getName()
    local charinfo = self.object.Functions.GetPlayerData().charinfo or {}
    return ((charinfo.firstname or "") .. " " .. (charinfo.lastname or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

---Current job name.
---@return string
function provider:getJob()
    local job = self.object.Functions.GetPlayerData().job
    return job and job.name or "unemployed"
end

---Current job grade level.
---@return integer
function provider:getJobRank()
    local job = self.object.Functions.GetPlayerData().job
    return tonumber(job and job.grade and job.grade.level) or 0
end

---Current gang name.
---@return string
function provider:getGang()
    local gang = self.object.Functions.GetPlayerData().gang
    return gang and gang.name or "none"
end

---Current gang grade level.
---@return integer
function provider:getGangRank()
    local gang = self.object.Functions.GetPlayerData().gang
    return tonumber(gang and gang.grade and gang.grade.level) or 0
end

---Whether the local player is on job duty.
---@return boolean
function provider:isOnJobDuty()
    local job = self.object.Functions.GetPlayerData().job
    if not job then return false end
    return job.onduty ~= false
end

---Whether the local player is on gang duty.
---@return boolean
function provider:isOnGangDuty()
    local gang = self.object.Functions.GetPlayerData().gang
    if not gang then return false end
    return gang.onduty ~= false
end

---Current balance of the requested account.
---@param accountName BridgeAccount
---@return integer
function provider:getAccount(accountName)
    local key = ({ money = "cash", black_money = "crypto" })[accountName] or accountName or "cash"
    local money = self.object.Functions.GetPlayerData().money or {}
    return money[key] or 0
end

---Revive the local player. Fades the screen out for the transition,
---performs the native revive (`NetworkResurrectLocalPlayer` + full HP +
---blood cleanup), clears post-death timecycle / motion-blur effects,
---then fades back in. Also clears the QB hospital death/laststand
---metadata so the framework UI stays in sync.
---@return boolean
function provider:revive()
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(50) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local x = math.floor(coords.x * 10 + 0.5) / 10
    local y = math.floor(coords.y * 10 + 0.5) / 10
    local z = math.floor(coords.z * 10 + 0.5) / 10
    NetworkResurrectLocalPlayer(x, y, z, GetEntityHeading(ped), true, false)
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
    SetPedMotionBlur(ped, false)

    if bridge.core.isStarted("qb-ambulancejob") then
        pcall(function()
            exports["qb-ambulancejob"]:RevivePlayer()
        end)
    end
    TriggerEvent("hospital:client:Revive")
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)

    DoScreenFadeIn(800)
    return true
end

---Clear the QB-tracked death and last-stand metadata.
function provider:clearDeathStatus()
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
end
