local Core = LyreBridge
local PlayerInternals = Core._serverPlayerInternals or {}

Core.registerModule("server", "players", function()
    local module = {}

    local function getNativeIdentifier(source)
        source = tonumber(source)
        if not source then
            return nil
        end

        if type(GetPlayerIdentifierByType) == "function" then
            local identifier = GetPlayerIdentifierByType(source, "license")
            if not identifier or identifier == "" then
                identifier = GetPlayerIdentifierByType(source, "license2")
            end
            if not identifier or identifier == "" then
                identifier = GetPlayerIdentifierByType(source, "steam")
            end
            if not identifier or identifier == "" then
                identifier = GetPlayerIdentifierByType(source, "fivem")
            end

            if identifier and identifier ~= "" then
                return identifier
            end
        end

        if type(GetPlayerIdentifier) ~= "function" then
            return nil
        end

        local identifierCount = type(GetNumPlayerIdentifiers) == "function" and GetNumPlayerIdentifiers(source) or 0
        for index = 0, identifierCount - 1 do
            local identifier = GetPlayerIdentifier(source, index)
            if identifier and identifier ~= "" then
                return identifier
            end
        end

        return nil
    end

    local function splitName(name)
        name = tostring(name or "")
        local firstName = name:match("([^%s]+)") or ""
        local lastName = name:match("%s(.+)$") or ""
        return firstName, lastName
    end

    local function createStandalonePlayer(source)
        source = tonumber(source)
        if not source or not GetPlayerName(source) then
            return false
        end

        local player = {
            source = source,
            raw = nil,
            standalone = true,
        }

        function player.getIdentifier()
            return getNativeIdentifier(source) or ("source:" .. tostring(source))
        end

        function player.getName()
            return GetPlayerName(source) or ("Player " .. tostring(source))
        end

        function player.getFirstName()
            local firstName = splitName(player.getName())
            return firstName
        end

        function player.getLastName()
            local _, lastName = splitName(player.getName())
            return lastName
        end

        function player.showNotification(message, notificationType, duration)
            if Core.isStarted("ox_lib") then
                TriggerClientEvent("ox_lib:notify", source, {
                    description = message or "",
                    type = notificationType or "inform",
                    duration = duration or 5000,
                })
                return
            end

            TriggerClientEvent("chat:addMessage", source, {
                args = { "Lyre", message or "" },
            })
        end

        function player.getAccount()
            return 0
        end

        function player.removeAccountMoney()
            return false
        end

        function player.addAccountMoney()
            return false
        end

        return player
    end

    local function wrapOrStandalone(player, source)
        if player then
            return player
        end

        return createStandalonePlayer(source)
    end

    function module.getRawPlayer(bridge, source)
        local framework = PlayerInternals.frameworkName(bridge)

        if framework == "ESX" then
            return PlayerInternals.getESXPlayer(source, bridge)
        end

        if framework == "QBCORE" then
            return PlayerInternals.getQBPlayer(source, bridge)
        end

        if framework == "QBOX" then
            return PlayerInternals.getQBoxPlayer(source, bridge)
        end

        return nil
    end

    function module.getPlayerFromId(bridge, source)
        local framework = PlayerInternals.frameworkName(bridge)

        if framework == "ESX" then
            return wrapOrStandalone(PlayerInternals.wrapESXPlayer(PlayerInternals.getESXPlayer(source, bridge), source), source)
        end

        if framework == "QBCORE" then
            return wrapOrStandalone(PlayerInternals.wrapQBPlayer(PlayerInternals.getQBPlayer(source, bridge), source), source)
        end

        if framework == "QBOX" then
            return wrapOrStandalone(PlayerInternals.wrapQBoxPlayer(PlayerInternals.getQBoxPlayer(source, bridge), source, bridge and bridge.object), source)
        end

        return createStandalonePlayer(source)
    end

    function module.getPlayerIdentifier(bridge, source)
        local player = module.getPlayerFromId(bridge, source)
        if not player then
            return nil
        end

        return player.getIdentifier()
    end

    function module.getIdentifierFromSource(bridge, source)
        return module.getPlayerIdentifier(bridge, source) or false
    end

    function module.getPlayerName(bridge, source)
        local player = module.getPlayerFromId(bridge, source)
        if not player then
            return nil, nil
        end

        return player.getFirstName(), player.getLastName()
    end

    function module.getPlayerDisplayName(bridge, source)
        local player = module.getPlayerFromId(bridge, source)
        if not player then
            return GetPlayerName(source) or ("Player " .. tostring(source))
        end

        return player.getName()
    end

    function module.showNotification(bridge, source, message, notificationType, duration)
        local player = module.getPlayerFromId(bridge, source)
        if not player then
            return false
        end

        player.showNotification(message, notificationType, duration)
        return true
    end

    function module.removePlayerMoney(bridge, source, account, amount)
        amount = tonumber(amount)
        if not amount or amount <= 0 then
            return false
        end

        local player = module.getPlayerFromId(bridge, source)
        if not player then
            return false
        end

        local currentAmount = tonumber(player.getAccount(account)) or 0
        if currentAmount < amount then
            return false
        end

        return player.removeAccountMoney(account, amount) == true
    end

    function module.getIdFromIdentifier(bridge, identifier)
        if not identifier then
            return false
        end

        local framework = PlayerInternals.frameworkName(bridge)
        local object = bridge and bridge.object

        if framework == "ESX" and object and type(object.GetPlayerFromIdentifier) == "function" then
            local player = object.GetPlayerFromIdentifier(identifier)
            return player and player.source or false
        end

        if framework == "QBCORE" and object and object.Functions and type(object.Functions.GetPlayerByCitizenId) == "function" then
            local player = object.Functions.GetPlayerByCitizenId(identifier)
            return player and (player.source or (player.PlayerData and player.PlayerData.source)) or false
        end

        if framework == "QBOX" and object and type(object.GetPlayersData) == "function" then
            for _, playerData in pairs(object:GetPlayersData() or {}) do
                if playerData.citizenid == identifier or playerData.identifier == identifier then
                    return tonumber(playerData.source) or false
                end
            end
        end

        return false
    end

    function module.getPlayerFromIdentifier(bridge, identifier)
        local source = module.getIdFromIdentifier(bridge, identifier)
        if not source then
            return false
        end

        return module.getPlayerFromId(bridge, source)
    end

    return module
end)
