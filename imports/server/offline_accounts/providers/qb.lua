local function accountName(account)
    if account == "money" then
        return "cash"
    end

    if account == "black_money" then
        return "crypto"
    end

    return account or "bank"
end

LyreBridge.registerProvider("server", "offlineAccounts", {
    name = "qb",
    priority = 110,
    isAvailable = function(self, context)
        return context.framework == "QBCORE" or context.framework == "QBOX"
    end,
    update = function(self, context)
        local response = MySQL.query.await("SELECT money FROM `players` WHERE `citizenid` = ? LIMIT 1", {
            context.identifier,
        })
        if not response or not response[1] then
            return true, false
        end

        local money = json.decode(response[1].money or "{}") or {}
        local column = accountName(context.account)
        money[column] = (money[column] or 0) + context.amount

        MySQL.update.await("UPDATE `players` SET `money` = ? WHERE `citizenid` = ?", {
            json.encode(money),
            context.identifier,
        })
        return true, true
    end,
})
