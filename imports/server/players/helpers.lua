local Core = LyreBridge
Core._serverPlayerInternals = Core._serverPlayerInternals or {}
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

local PlayerInternals = Core._serverPlayerInternals
PlayerInternals.frameworkName = frameworkName
PlayerInternals.esxAccountName = esxAccountName
PlayerInternals.qbAccountName = qbAccountName
PlayerInternals.joinName = joinName
PlayerInternals.getESXPlayer = getESXPlayer
PlayerInternals.getQBPlayer = getQBPlayer
PlayerInternals.getQBoxPlayer = getQBoxPlayer
