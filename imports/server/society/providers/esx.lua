local function societyAccount(jobName)
    if LyreBridge.isStarted("esx_society") then
        local society = exports["esx_society"]:GetSociety(jobName)
        if society and society.account then
            return society.account
        end
    end

    return "society_" .. jobName
end

LyreBridge.registerProvider("server", "society", {
    name = "esx",
    priority = 100,
    isAvailable = function(self, context)
        return context.framework == "ESX"
    end,
    getMoney = function(self, context)
        local accountName = societyAccount(context.jobName)
        local money = MySQL.scalar.await("SELECT money FROM addon_account_data WHERE account_name = ?", { accountName })
        return true, tonumber(money) or 0
    end,
    removeMoney = function(self, context)
        local accountName = societyAccount(context.jobName)
        if LyreBridge.isStarted("esx_addonaccount") then
            TriggerEvent("esx_addonaccount:getSharedAccount", accountName, function(account)
                if account then
                    account.removeMoney(context.amount)
                end
            end)
            return true, true
        end

        local affected = MySQL.update.await("UPDATE addon_account_data SET money = money - ? WHERE account_name = ? AND money >= ?", {
            context.amount,
            accountName,
            context.amount,
        })
        return true, affected and affected > 0
    end,
})
