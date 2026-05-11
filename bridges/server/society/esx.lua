local provider = LyreBridge.registerProvider("server", "society", "esx", 10)

function provider:detect()
    return bridge.core:isStarted("es_extended") and bridge.core:isStarted("esx_addonaccount")
end

function provider:getMoney(jobName)
    local account
    TriggerEvent("esx_addonaccount:getSharedAccount", "society_" .. jobName, function(result)
        account = result
    end)
    return account and account.money or 0
end

function provider:addMoney(jobName, amount)
    local account
    TriggerEvent("esx_addonaccount:getSharedAccount", "society_" .. jobName, function(result)
        account = result
    end)
    if not account then return false end
    account.addMoney(amount)
    return true
end

function provider:removeMoney(jobName, amount)
    local account
    TriggerEvent("esx_addonaccount:getSharedAccount", "society_" .. jobName, function(result)
        account = result
    end)
    if not account or account.money < amount then return false end
    account.removeMoney(amount)
    return true
end
