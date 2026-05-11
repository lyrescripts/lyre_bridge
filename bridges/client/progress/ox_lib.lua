local provider = LyreBridge.registerProvider("client", "progress", "ox_lib", 10)

function provider:detect()
    return bridge.core:isStarted("ox_lib") and lib and type(lib.progressCircle) == "function"
end

function provider:run(options)
    if options.circle then
        return lib.progressCircle(options)
    end
    return lib.progressBar(options)
end
