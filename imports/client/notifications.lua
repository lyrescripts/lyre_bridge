local Core = LyreBridge
Core.registerModule("client", "notifications", function()
    local module = {}

    local function frameworkNotify(bridge, message, notificationType, duration)
        if type(bridge) == "table" and type(bridge.object) == "table" then
            if type(bridge.object.ShowNotification) == "function" then
                bridge.object.ShowNotification(message)
                return true
            end

            if bridge.object.Functions and type(bridge.object.Functions.Notify) == "function" then
                bridge.object.Functions.Notify(message, notificationType or "success", duration or 5000)
                return true
            end
        end

        if Core.isStarted("es_extended") then
            local ok = pcall(function()
                local esx = exports["es_extended"]:getSharedObject()
                if esx and type(esx.ShowNotification) == "function" then
                    esx.ShowNotification(message)
                else
                    error("esx_notification_missing")
                end
            end)
            if ok then
                return true
            end
        end

        if Core.isStarted("qb-core") then
            local ok = pcall(function()
                local qb = exports["qb-core"]:GetCoreObject()
                qb.Functions.Notify(message, notificationType or "success", duration or 5000)
            end)
            if ok then
                return true
            end
        end

        return false
    end

    function module.show(message, notificationType, duration, bridge)
        message = tostring(message or "")
        notificationType = notificationType or "inform"

        if Core.isStarted("ox_lib") and lib and type(lib.notify) == "function" then
            lib.notify({
                description = message,
                type = notificationType,
                duration = duration or 5000,
            })
            return true
        end

        if frameworkNotify(bridge, message, notificationType, duration) then
            return true
        end

        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
        return true
    end

    function module.help(message, bridge)
        message = tostring(message or "")

        if type(bridge) == "table"
            and type(bridge.object) == "table"
            and type(bridge.object.ShowHelpNotification) == "function"
        then
            bridge.object.ShowHelpNotification(message)
            return true
        end

        SetTextComponentFormat("STRING")
        AddTextComponentString(message)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        return true
    end

    return module
end)
