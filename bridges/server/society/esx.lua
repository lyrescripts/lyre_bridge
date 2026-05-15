local provider = LyreBridge.registerProvider("server", "society", "esx", 10)

---Active when both `es_extended` and `esx_addonaccount` are started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended") and bridge.core.isStarted("esx_addonaccount")
end

---Read the society's current cash balance.
---@param jobName string
---@return integer
function provider:getMoney(jobName)
    local account
    TriggerEvent("esx_addonaccount:getSharedAccount", "society_" .. jobName, function(result)
        account = result
    end)
    return account and account.money or 0
end

---Credit the society account.
---@param jobName string
---@param amount integer
---@return boolean
function provider:addMoney(jobName, amount)
    local account
    TriggerEvent("esx_addonaccount:getSharedAccount", "society_" .. jobName, function(result)
        account = result
    end)
    if not account then return false end
    account.addMoney(amount)
    return true
end

---Debit the society account.
---@param jobName string
---@param amount integer
---@return boolean
function provider:removeMoney(jobName, amount)
    local account
    TriggerEvent("esx_addonaccount:getSharedAccount", "society_" .. jobName, function(result)
        account = result
    end)
    if not account or account.money < amount then return false end
    account.removeMoney(amount)
    return true
end
