local provider = LyreBridge.registerProvider("client", "progress", "ox_lib", 10)

---Active when the `ox_lib` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ox_lib")
end

---Run a progress bar and resolve once it ends.
---@param options BridgeProgressOptions `circle = true` renders the radial variant.
---@return boolean completed false when the player cancelled.
function provider:run(options)
    if options.circle then
        return exports.ox_lib:progressCircle(options)
    end
    return exports.ox_lib:progressBar(options)
end
