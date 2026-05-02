if not LyreBridge or not LyreBridge.setupBridge then
    local runtime = LoadResourceFile("lyre_bridge", "imports/shared.lua")
    assert(runtime, "lyre_bridge imports/shared.lua is missing")

    local fn, err = load(runtime, "@lyre_bridge/imports/shared.lua")
    assert(fn, err)
    fn()
end

local Core = LyreBridge

local function currentResourceName()
    if type(GetCurrentResourceName) == "function" then
        return GetCurrentResourceName()
    end

    return "unknown"
end

local function readBoolConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local sentinel = "__lyre_bridge_unset__"
    local value = GetConvar(name, sentinel)
    if value == sentinel or value == "" then
        return default
    end

    value = string.lower(tostring(value))
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

local function resourceSqlStrict(resourceName, default)
    local names = {
        "lyre_bridge:" .. resourceName .. ":sqlStrict",
        resourceName .. ":sqlStrict",
    }

    local value = default
    for _, name in ipairs(names) do
        value = readBoolConvar(name, value)
    end

    return value
end

local function getRequiredFunctions(config, options)
    if type(options.required) == "table" then
        return options.required
    end

    if type(config) == "table" then
        return config.bridgeRequiredServerFunctions
    end

    return nil
end

function Core.ensureResourceSql(resourceName, options)
    resourceName = resourceName or currentResourceName()
    options = options or {}

    if not Core.isStarted("lyre_bridge") then
        return false, Core.fail("lyre_bridge_not_started", "lyre_bridge must be started before SQL can be prepared.", {
            resource = resourceName,
            side = "server",
        })
    end

    local ok, result = pcall(function()
        return exports["lyre_bridge"]:EnsureResourceSchema(resourceName, options)
    end)

    if not ok then
        return false, Core.fail("sql_prepare_export_failed", tostring(result), {
            resource = resourceName,
            side = "server",
        })
    end

    if type(result) == "table" and result.ok == false then
        Core.log("error", result.message or "SQL preparation failed.", {
            resource = resourceName,
            side = "server",
            code = result.code,
        })
        return false, result
    end

    return true, result
end

function Core.prepareResourceSql(resourceName, config, options)
    options = options or {}
    config = config or _G.Config or {}
    resourceName = resourceName or options.resource or currentResourceName()

    local sqlOptions = {}
    if type(options.sqlOptions) == "table" then
        for key, value in pairs(options.sqlOptions) do
            sqlOptions[key] = value
        end
    end

    sqlOptions.strict = resourceSqlStrict(resourceName, sqlOptions.strict == true or options.strict == true)
    sqlOptions.bridge = options.bridge or sqlOptions.bridge or (type(config) == "table" and config.bridge)

    return Core.ensureResourceSql(resourceName, sqlOptions)
end

function Core.setupServerResourceBridge(config, options)
    options = options or {}
    config = config or _G.Config or {}

    local resourceName = options.resource or currentResourceName()
    Core._serverBridgeSetup = Core._serverBridgeSetup or {}

    if Core._serverBridgeSetup[resourceName] then
        return true, _G.bridge
    end

    Core._serverBridgeSetup[resourceName] = true

    local sqlSuccess, sqlResult = Core.prepareResourceSql(resourceName, config, options)
    if not sqlSuccess then
        Core._serverBridgeSetup[resourceName] = nil
        Core.log("error", sqlResult and sqlResult.message or "Automatic SQL preparation failed.", {
            resource = resourceName,
            side = "server",
        })
        return false, sqlResult
    end

    local setupOptions = {}
    for key, value in pairs(options) do
        setupOptions[key] = value
    end

    setupOptions.resource = resourceName
    setupOptions.required = getRequiredFunctions(config, options)

    local success, result = Core.setupBridge("server", _G.bridge, config, setupOptions)
    if not success then
        Core._serverBridgeSetup[resourceName] = nil
        Core.log("error", result and result.message or "Unable to setup the server bridge.", {
            resource = resourceName,
            side = "server",
        })
        return false, result
    end

    return true, result
end

Core.registerModule("server", "sql", function()
    local module = {}

    function module.ensure(resourceName, options)
        return Core.ensureResourceSql(resourceName, options)
    end

    function module.query(query, params)
        return exports["lyre_bridge"]:SqlQuery(query, params)
    end

    function module.single(query, params)
        return exports["lyre_bridge"]:SqlSingle(query, params)
    end

    function module.scalar(query, params)
        return exports["lyre_bridge"]:SqlScalar(query, params)
    end

    function module.update(query, params)
        return exports["lyre_bridge"]:SqlUpdate(query, params)
    end

    function module.insert(query, params)
        return exports["lyre_bridge"]:SqlInsert(query, params)
    end

    return module
end)

Core.registerModule("server", "framework", function()
    local module = {}

    function module.getESX()
        if not Core.isStarted("es_extended") then
            return nil, "es_extended_not_started"
        end

        local ok, object = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)

        if not ok then
            return nil, object
        end

        return object
    end

    function module.getQBCore()
        if not Core.isStarted("qb-core") then
            return nil, "qb_core_not_started"
        end

        local ok, object = pcall(function()
            return exports["qb-core"]:GetCoreObject()
        end)

        if not ok then
            return nil, object
        end

        return object
    end

    function module.getQBox()
        if not Core.isStarted("qbx_core") then
            return nil, "qbx_core_not_started"
        end

        return exports["qbx_core"]
    end

    return module
end)

Core.registerModule("server", "players", function()
    local module = {}

    local function frameworkName(bridge)
        return bridge and bridge.__lyre and bridge.__lyre.framework
    end

    local function esxAccountName(account)
        if account == "cash" then
            return "money"
        end

        return account or "money"
    end

    local function qbAccountName(account)
        if account == "money" or account == "cash" then
            return "cash"
        end

        if account == "black_money" or account == "crypto" then
            return "crypto"
        end

        return account or "cash"
    end

    local function trim(value)
        return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
    end

    local function joinName(firstName, lastName, fallback)
        local fullName = trim((firstName or "") .. " " .. (lastName or ""))
        if fullName ~= "" then
            return fullName
        end

        return fallback
    end

    local function getESXPlayer(source, bridge)
        local object = bridge and bridge.object
        if not object and Core.isStarted("es_extended") then
            local framework = Core.getModule("server", "framework")
            object = framework and framework.getESX and framework.getESX()
        end

        if not object or type(object.GetPlayerFromId) ~= "function" then
            return nil
        end

        return object.GetPlayerFromId(source)
    end

    local function getQBPlayer(source, bridge)
        local object = bridge and bridge.object
        if not object and Core.isStarted("qb-core") then
            local framework = Core.getModule("server", "framework")
            object = framework and framework.getQBCore and framework.getQBCore()
        end

        if not object or not object.Functions or type(object.Functions.GetPlayer) ~= "function" then
            return nil
        end

        return object.Functions.GetPlayer(source)
    end

    local function getQBoxPlayer(source, bridge)
        local object = bridge and bridge.object
        if not object and Core.isStarted("qbx_core") then
            local framework = Core.getModule("server", "framework")
            object = framework and framework.getQBox and framework.getQBox()
        end

        if not object or type(object.GetPlayer) ~= "function" then
            return nil
        end

        return object:GetPlayer(source)
    end

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

    function module.getRawPlayer(bridge, source)
        local framework = frameworkName(bridge)

        if framework == "ESX" then
            return getESXPlayer(source, bridge)
        end

        if framework == "QBCORE" then
            return getQBPlayer(source, bridge)
        end

        if framework == "QBOX" then
            return getQBoxPlayer(source, bridge)
        end

        return nil
    end

    function module.getPlayerFromId(bridge, source)
        local framework = frameworkName(bridge)

        if framework == "ESX" then
            return wrapESXPlayer(getESXPlayer(source, bridge), source)
        end

        if framework == "QBCORE" then
            return wrapQBPlayer(getQBPlayer(source, bridge), source)
        end

        if framework == "QBOX" then
            return wrapQBoxPlayer(getQBoxPlayer(source, bridge), source, bridge and bridge.object)
        end

        return false
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

        local framework = frameworkName(bridge)
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
