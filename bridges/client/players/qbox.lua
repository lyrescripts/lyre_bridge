local provider = LyreBridge.registerProvider("client", "players", "qbox", 5)

---Active when the `qbx_core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core")
end

---Cache the qbx_core exports handle for later calls.
function provider:init()
    self.object = exports.qbx_core
    self.__groupsFrame = nil
    self.__groupsData = nil
end

---Raw qbx_core player-data table.
---@return table
function provider:getData()
    return self.object:GetPlayerData()
end

---Persistent citizen id of the local player.
---@return string
function provider:getIdentifier()
    local data = self.object:GetPlayerData()
    return data.citizenid or data.identifier
end

---Display name of the local player.
---@return string
function provider:getName()
    local charinfo = self.object:GetPlayerData().charinfo or {}
    local first = charinfo.firstname or charinfo.firstName or ""
    local last = charinfo.lastname or charinfo.lastName or ""
    return (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
end

---Share the framework export read between group accessors in a frame.
---Raw getData(), money and identity reads keep their live behavior.
---@return table data Current frame's framework data.
function provider:__getGroupsData()
    local frame = GetFrameCount()
    if self.__groupsFrame ~= frame then
        self.__groupsData = self.object:GetPlayerData()
        self.__groupsFrame = frame
    end
    return self.__groupsData
end

---Current job name.
---@return string
function provider:getJob()
    local job = self:__getGroupsData().job
    return job and job.name or "unemployed"
end

---Current job grade level.
---@return integer
function provider:getJobRank()
    local job = self:__getGroupsData().job
    return tonumber(job and job.grade and job.grade.level) or 0
end

---Current gang name.
---@return string
function provider:getGang()
    local gang = self:__getGroupsData().gang
    return gang and gang.name or "none"
end

---Current gang grade level.
---@return integer
function provider:getGangRank()
    local gang = self:__getGroupsData().gang
    return tonumber(gang and gang.grade and gang.grade.level) or 0
end

---Whether the local player is on job duty.
---@return boolean
function provider:isOnJobDuty()
    local job = self.object:GetPlayerData().job
    if not job then return false end
    return job.onduty ~= false
end

---Whether the local player is on gang duty.
---@return boolean
function provider:isOnGangDuty()
    local gang = self.object:GetPlayerData().gang
    if not gang then return false end
    return gang.onduty ~= false
end

---Current balance of the requested account.
---@param accountName BridgeAccount
---@return integer
function provider:getAccount(accountName)
    local key = ({ money = "cash", black_money = "crypto" })[accountName] or accountName or "cash"
    local money = self.object:GetPlayerData().money or {}
    return money[key] or 0
end

---Revive the local player. Fades the screen out for the transition,
---performs the native revive (`NetworkResurrectLocalPlayer` + full HP +
---blood cleanup), clears post-death timecycle / motion-blur effects,
---then fades back in. Also clears the qbx hospital death/laststand
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

local groupEvents = {
    "QBCore:Client:OnPlayerLoaded", "QBCore:Client:OnPlayerUnload",
    "QBCore:Player:SetPlayerData", "QBCore:Client:OnJobUpdate", "QBCore:Client:OnGangUpdate",
    "qbx_core:client:onGroupUpdate", "qbx_core:client:onJobUpdate", "qbx_core:client:onGangUpdate",
}
for i = 1, #groupEvents do
    RegisterNetEvent(groupEvents[i], function()
        provider.__groupsFrame = nil
        provider.__groupsData = nil
    end)
end

AddEventHandler("onClientResourceStop", function(resource)
    if resource == "qbx_core" then
        provider.__groupsFrame = nil
        provider.__groupsData = nil
    end
end)
AddEventHandler("onClientResourceStart", function(resource)
    if resource == "qbx_core" then
        provider.__groupsFrame = nil
        provider.__groupsData = nil
    end
end)
