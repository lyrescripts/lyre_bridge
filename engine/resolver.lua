---Resolve the active provider for a module on a given side. Honors the
---`lyre_bridge:provider:<side>:<module>:force` and
---`lyre_bridge:provider:<side>:<module>:disabled` convars before falling back
---to each provider's `detect()` callback. The selected provider's `init()` is
---invoked exactly once.
---@param side BridgeSide
---@param moduleName string
---@return Provider?
function LyreBridge.resolveProvider(side, moduleName)
    for _, sideToCheck in ipairs({ side, "shared" }) do
        local bucket = LyreBridge.providers[sideToCheck] and LyreBridge.providers[sideToCheck][moduleName]
        if bucket then
            local forced
            for _, convar in ipairs({
                ("lyre_bridge:provider:%s:%s:force"):format(sideToCheck, moduleName),
                ("lyre_bridge:provider:%s:force"):format(moduleName),
            }) do
                local value = GetConvar(convar, "")
                if value ~= "" then
                    forced = string.lower(value)
                    break
                end
            end

            local disabled = {}
            for _, convar in ipairs({
                ("lyre_bridge:provider:%s:%s:disabled"):format(sideToCheck, moduleName),
                ("lyre_bridge:provider:%s:disabled"):format(moduleName),
            }) do
                local value = GetConvar(convar, "")
                if value ~= "" then
                    for entry in value:gmatch("[^,%s]+") do
                        disabled[string.lower(entry)] = true
                    end
                end
            end

            for _, provider in ipairs(bucket) do
                local nameLower = string.lower(provider.__name)
                local eligible = forced and nameLower == forced
                    or (not forced and type(provider.detect) == "function" and not disabled[nameLower])

                if eligible then
                    local detected = forced ~= nil
                    if not forced then
                        local ok, result = pcall(provider.detect, provider)
                        detected = ok and result
                    end

                    if detected then
                        if not provider.__active then
                            if type(provider.init) == "function" then
                                local ok, err = pcall(provider.init, provider)
                                if not ok then
                                    print(("[lyre_bridge][ERROR] Provider %s/%s init failed: %s"):format(
                                        provider.__module, provider.__name, tostring(err)
                                    ))
                                end
                            end
                            provider.__active = true
                        end
                        return provider
                    end
                end
            end
        end
    end

    return nil
end
