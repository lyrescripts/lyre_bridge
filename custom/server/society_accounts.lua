-- Example: centralize society account deposits.
--[[
LyreBridge.registerModule("server", "society", function()
    return {
        addMoney = function(account, amount)
            TriggerEvent("esx_addonaccount:getSharedAccount", account, function(sharedAccount)
                if sharedAccount then
                    sharedAccount.addMoney(amount)
                end
            end)
            return true
        end,
    }
end)
]]
