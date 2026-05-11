local provider = LyreBridge.registerProvider("client", "progress", "native", 1000)

function provider:detect()
    return true
end

function provider:run(options)
    local duration = tonumber(options.duration) or 0
    if duration > 0 then
        Wait(duration)
    end
    return true
end
