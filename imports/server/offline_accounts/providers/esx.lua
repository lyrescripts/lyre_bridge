LyreBridge.registerProvider("server", "offlineAccounts", {
    name = "esx",
    priority = 100,
    isAvailable = function(self, context)
        return context.framework == "ESX"
    end,
    update = function(self, context)
        local response = MySQL.query.await("SELECT accounts FROM `users` WHERE `identifier` = ? LIMIT 1", {
            context.identifier,
        })
        if not response or not response[1] then
            return true, false
        end

        local accounts = json.decode(response[1].accounts or "{}") or {}
        if accounts[context.account] == nil then
            return true, false
        end

        accounts[context.account] = accounts[context.account] + context.amount
        MySQL.update.await("UPDATE `users` SET `accounts` = ? WHERE `identifier` = ?", {
            json.encode(accounts),
            context.identifier,
        })
        return true, true
    end,
})
