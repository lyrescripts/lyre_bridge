local provider = LyreBridge.registerProvider("client", "players", "qbox", 5)

---Active when the `qbx_core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core")
end

---Cache the qbx_core exports handle for later calls.
function provider:init()
    self.object = exports.qbx_core
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

---Current job info.
---@return table
function provider:getJob()
    return self.object:GetPlayerData().job
end

---Current gang info, or `nil` when not in a gang.
---@return table?
function provider:getGang()
    return self.object:GetPlayerData().gang
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

---Revive the local player via the hospital script.
---@return boolean
function provider:revive()
    TriggerEvent("hospital:client:Revive")
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
    return true
end

---Clear the QB-tracked death and last-stand metadata.
function provider:clearDeathStatus()
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
end
