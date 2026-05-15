local provider = LyreBridge.registerProvider("client", "progress", "ox_lib", 10)

---Active when `ox_lib` is started and exposes `lib.progressCircle`.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ox_lib") and lib and type(lib.progressCircle) == "function"
end

---Run a progress bar and resolve once it ends.
---@param options BridgeProgressOptions `circle = true` renders the radial variant.
---@return boolean completed false when the player cancelled.
function provider:run(options)
    if options.circle then
        return lib.progressCircle(options)
    end
    return lib.progressBar(options)
end
