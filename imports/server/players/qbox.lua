local Core = LyreBridge
local PlayerInternals = Core._serverPlayerInternals or {}
local qbAccountName = PlayerInternals.qbAccountName
local joinName = PlayerInternals.joinName
    local function wrapQBoxPlayer(qboxPlayer, source, bridgeObject)
        if not qboxPlayer then
            return false
        end

        local playerData = qboxPlayer.PlayerData or qboxPlayer
        local charinfo = playerData.charinfo or {}
        local player = {
            source = source or playerData.source,
            raw = qboxPlayer,
        }

        function player.getIdentifier()
            return playerData.citizenid or playerData.identifier
        end

        function player.getName()
            local firstName = charinfo.firstname or charinfo.firstName
            local lastName = charinfo.lastname or charinfo.lastName
            return joinName(firstName, lastName, GetPlayerName(player.source))
        end

        function player.getFirstName()
            return charinfo.firstname or charinfo.firstName or ""
        end

        function player.getLastName()
            return charinfo.lastname or charinfo.lastName or ""
        end

        function player.showNotification(message, notificationType, duration)
            if bridgeObject and type(bridgeObject.Notify) == "function" then
                bridgeObject:Notify(player.source, message or "", notificationType or "inform", duration or 5000)
                return
            end

            TriggerClientEvent("ox_lib:notify", player.source, {
                description = message or "",
                type = notificationType or "inform",
                duration = duration or 5000,
            })
        end

        function player.getAccount(account)
            local accountName = qbAccountName(account)
            return (playerData.money and playerData.money[accountName]) or 0
        end

        function player.removeAccountMoney(account, amount)
            if type(qboxPlayer.RemoveMoney) == "function" then
                qboxPlayer:RemoveMoney(qbAccountName(account), amount)
                return true
            end

            if bridgeObject and type(bridgeObject.RemoveMoney) == "function" then
                bridgeObject:RemoveMoney(player.source, qbAccountName(account), amount)
                return true
            end

            return false
        end

        function player.addAccountMoney(account, amount)
            if type(qboxPlayer.AddMoney) == "function" then
                qboxPlayer:AddMoney(qbAccountName(account), amount)
                return true
            end

            if bridgeObject and type(bridgeObject.AddMoney) == "function" then
                bridgeObject:AddMoney(player.source, qbAccountName(account), amount)
                return true
            end

            return false
        end

        return player
    end
PlayerInternals.wrapQBoxPlayer = wrapQBoxPlayer
