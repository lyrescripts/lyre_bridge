local Core = LyreBridge
local PlayerInternals = Core._serverPlayerInternals or {}
local qbAccountName = PlayerInternals.qbAccountName
local joinName = PlayerInternals.joinName
    local function wrapQBPlayer(qbPlayer, source)
        if not qbPlayer then
            return false
        end

        local playerData = qbPlayer.PlayerData or {}
        local charinfo = playerData.charinfo or {}
        local player = {
            source = source or playerData.source,
            raw = qbPlayer,
        }

        function player.getIdentifier()
            return playerData.citizenid
        end

        function player.getName()
            return joinName(charinfo.firstname, charinfo.lastname, GetPlayerName(player.source))
        end

        function player.getFirstName()
            return charinfo.firstname or ""
        end

        function player.getLastName()
            return charinfo.lastname or ""
        end

        function player.showNotification(message, notificationType, duration)
            TriggerClientEvent("QBCore:Notify", player.source, message or "", notificationType or "success", duration or 5000)
        end

        function player.getAccount(account)
            local accountName = qbAccountName(account)
            return (playerData.money and playerData.money[accountName]) or 0
        end

        function player.removeAccountMoney(account, amount)
            if not qbPlayer.Functions or type(qbPlayer.Functions.RemoveMoney) ~= "function" then
                return false
            end

            qbPlayer.Functions.RemoveMoney(qbAccountName(account), amount, "")
            return true
        end

        function player.addAccountMoney(account, amount)
            if not qbPlayer.Functions or type(qbPlayer.Functions.AddMoney) ~= "function" then
                return false
            end

            qbPlayer.Functions.AddMoney(qbAccountName(account), amount, "")
            return true
        end

        return player
    end
PlayerInternals.wrapQBPlayer = wrapQBPlayer
