local Core = LyreBridge
local PlayerInternals = Core._serverPlayerInternals or {}
local esxAccountName = PlayerInternals.esxAccountName
    local function wrapESXPlayer(xPlayer, source)
        if not xPlayer then
            return false
        end

        local player = {
            source = source or xPlayer.source,
            raw = xPlayer,
        }

        function player.getIdentifier()
            if type(xPlayer.getIdentifier) == "function" then
                return xPlayer.getIdentifier()
            end

            return xPlayer.identifier
        end

        function player.getName()
            if type(xPlayer.getName) == "function" then
                return xPlayer.getName()
            end

            return GetPlayerName(player.source)
        end

        function player.getFirstName()
            if type(xPlayer.get) == "function" then
                local firstName = xPlayer.get("firstName")
                if firstName then
                    return firstName
                end
            end

            local name = player.getName()
            local firstName = name and name:match("([^%s]+)")
            return firstName or ""
        end

        function player.getLastName()
            if type(xPlayer.get) == "function" then
                local lastName = xPlayer.get("lastName")
                if lastName then
                    return lastName
                end
            end

            local name = player.getName()
            local lastName = name and name:match("%s(.+)$")
            return lastName or ""
        end

        function player.showNotification(message)
            if type(xPlayer.showNotification) == "function" then
                xPlayer.showNotification(message)
                return
            end

            TriggerClientEvent("esx:showNotification", player.source, message or "")
        end

        function player.getAccount(account)
            if type(xPlayer.getAccount) ~= "function" then
                return 0
            end

            local data = xPlayer.getAccount(esxAccountName(account))
            if type(data) == "table" then
                return data.money or data.balance or 0
            end

            return tonumber(data) or 0
        end

        function player.removeAccountMoney(account, amount)
            if type(xPlayer.removeAccountMoney) ~= "function" then
                return false
            end

            xPlayer.removeAccountMoney(esxAccountName(account), amount)
            return true
        end

        function player.addAccountMoney(account, amount)
            if type(xPlayer.addAccountMoney) ~= "function" then
                return false
            end

            xPlayer.addAccountMoney(esxAccountName(account), amount)
            return true
        end

        return player
    end
PlayerInternals.wrapESXPlayer = wrapESXPlayer
