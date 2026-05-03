-- Example: update offline accounts through SQL.
--[[
LyreBridge.registerModule("server", "offlineAccounts", function()
    return {
        addMoney = function(identifier, account, amount)
            local row = MySQL.single.await("SELECT accounts FROM users WHERE identifier = ?", { identifier })
            if not row then
                return false
            end

            local accounts = json.decode(row.accounts or "{}")
            accounts[account] = (accounts[account] or 0) + amount
            MySQL.update.await("UPDATE users SET accounts = ? WHERE identifier = ?", { json.encode(accounts), identifier })
            return true
        end,
    }
end)
]]
