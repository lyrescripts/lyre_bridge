local Core = LyreBridge
Core.registerModule("client", "progress", function()
    local module = {}

    local function normalizeProgress(first, second, third)
        if type(first) == "table" then
            return first
        end

        local extra = type(third) == "table" and third or {}
        return {
            duration = tonumber(first) or extra.duration or 0,
            label = second or extra.label or extra.text,
            useWhileDead = extra.useWhileDead or false,
            canCancel = extra.canCancel or false,
            disable = extra.disable or {
                move = extra.disableMove ~= false,
                car = extra.disableCar ~= false,
                combat = extra.disableCombat ~= false,
            },
            anim = extra.anim,
            prop = extra.prop,
        }
    end

    function module.run(first, second, third)
        local options = normalizeProgress(first, second, third)

        if Core.isStarted("ox_lib") and lib then
            if type(lib.progressCircle) == "function" then
                return lib.progressCircle(options)
            end

            if type(lib.progressBar) == "function" then
                return lib.progressBar(options)
            end
        end

        if options.duration and options.duration > 0 then
            Wait(options.duration)
        end

        return true
    end

    return module
end)
