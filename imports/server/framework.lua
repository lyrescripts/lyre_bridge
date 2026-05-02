local Core = LyreBridge
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
