local provider = LyreBridge.registerProvider("client", "progress", "native", 1000)

---Always active; the native wait loop is the universal fallback.
---@return boolean
function provider:detect()
    return true
end

---Run a progress bar and resolve once it ends.
---@param options BridgeProgressOptions
---@return boolean completed Always true since native progress cannot be cancelled.
function provider:run(options)
    local duration = tonumber(options.duration) or 0
    if duration > 0 then
        Wait(duration)
    end
    return true
end
