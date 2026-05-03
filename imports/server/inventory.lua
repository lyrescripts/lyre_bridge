local Core = LyreBridge

Core.registerModule("server", "inventory", function()
    local module = {}

    local function frameworkName(bridge)
        return bridge and bridge.__lyre and bridge.__lyre.framework
    end

    local function callProvider(methodName, context)
        context.method = methodName

        for _, provider in ipairs(Core.getProviders("server", "inventory")) do
            if type(provider[methodName]) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled, result = pcall(provider[methodName], provider, context)
                if ok and handled then
                    Core.log("debug", "Inventory provider handled request.", {
                        provider = Core.providerName(provider),
                        method = methodName,
                        framework = context.framework,
                    })
                    return true, result
                end

                if not ok then
                    Core.log("warn", "Inventory provider failed.", {
                        provider = Core.providerName(provider),
                        method = methodName,
                        error = tostring(handled),
                    })
                end
            end
        end

        return false
    end

    local function createContext(bridge, player, extra)
        local context = {
            bridge = bridge,
            player = player,
            raw = player and player.raw,
            source = player and player.source,
            framework = frameworkName(bridge),
        }

        for key, value in pairs(extra or {}) do
            context[key] = value
        end

        return context
    end

    function module.addItem(bridge, player, itemName, count, metadata)
        local handled, result = callProvider("addItem", createContext(bridge, player, {
            itemName = itemName,
            count = tonumber(count) or 1,
            metadata = metadata,
        }))

        return handled and result ~= false
    end

    function module.removeItem(bridge, player, itemName, count, slot)
        local handled, result = callProvider("removeItem", createContext(bridge, player, {
            itemName = itemName,
            count = tonumber(count) or 1,
            slot = slot,
        }))

        return handled and result ~= false
    end

    function module.getItemCount(bridge, player, itemName)
        local handled, result = callProvider("getItemCount", createContext(bridge, player, {
            itemName = itemName,
        }))

        return handled and (tonumber(result) or 0) or 0
    end

    function module.setItemMetadata(bridge, player, itemName, slot, metadata)
        local handled, result = callProvider("setItemMetadata", createContext(bridge, player, {
            itemName = itemName,
            slot = tonumber(slot),
            metadata = metadata,
        }))

        return handled and result ~= false
    end

    function module.getItemBySlot(bridge, player, slot)
        local handled, result = callProvider("getItemBySlot", createContext(bridge, player, {
            slot = tonumber(slot),
        }))

        return handled and result or nil
    end

    function module.supportsMetadata(bridge)
        local handled, result = callProvider("supportsMetadata", {
            bridge = bridge,
            framework = frameworkName(bridge),
        })

        return handled and result == true
    end

    function module.enrichPlayer(bridge, player)
        if type(player) ~= "table" then
            return player
        end

        if type(player.addItem) ~= "function" then
            function player.addItem(itemName, count, metadata)
                return module.addItem(bridge, player, itemName, count, metadata)
            end
        end

        if type(player.removeItem) ~= "function" then
            function player.removeItem(itemName, count, slot)
                return module.removeItem(bridge, player, itemName, count, slot)
            end
        end

        if type(player.getItemCount) ~= "function" then
            function player.getItemCount(itemName)
                return module.getItemCount(bridge, player, itemName)
            end
        end

        if type(player.setItemMetadata) ~= "function" then
            function player.setItemMetadata(itemName, slot, metadata)
                return module.setItemMetadata(bridge, player, itemName, slot, metadata)
            end
        end

        if type(player.getItemBySlot) ~= "function" then
            function player.getItemBySlot(slot)
                return module.getItemBySlot(bridge, player, slot)
            end
        end

        return player
    end

    return module
end)
