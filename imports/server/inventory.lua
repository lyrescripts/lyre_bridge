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

    function module.hasItem(bridge, player, itemName, count)
        return module.getItemCount(bridge, player, itemName) >= (tonumber(count) or 1)
    end

    function module.canCarryItem(bridge, player, itemName, count)
        local handled, result = callProvider("canCarryItem", createContext(bridge, player, {
            itemName = itemName,
            count = tonumber(count) or 1,
        }))

        if not handled then
            return true
        end

        return result ~= false
    end

    function module.addAmmo(bridge, player, ammoItem, weaponName, amount)
        local handled, result = callProvider("addAmmo", createContext(bridge, player, {
            itemName = ammoItem,
            ammoItem = ammoItem,
            weaponName = weaponName,
            count = tonumber(amount) or 1,
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

        local useAdapterInventory = bridge and bridge.__lyreUseAdapterInventory == true

        if not useAdapterInventory then
            function player.addItem(itemName, count, metadata)
                return module.addItem(bridge, player, itemName, count, metadata)
            end

            function player.removeItem(itemName, count, slot)
                return module.removeItem(bridge, player, itemName, count, slot)
            end

            function player.getItemCount(itemName)
                return module.getItemCount(bridge, player, itemName)
            end

            function player.hasItem(itemName, count)
                return module.hasItem(bridge, player, itemName, count)
            end

            function player.canCarryItem(itemName, count)
                return module.canCarryItem(bridge, player, itemName, count)
            end

            function player.addAmmo(ammoItem, weaponName, amount)
                return module.addAmmo(bridge, player, ammoItem, weaponName, amount)
            end

            function player.setItemMetadata(itemName, slot, metadata)
                return module.setItemMetadata(bridge, player, itemName, slot, metadata)
            end

            function player.getItemBySlot(slot)
                return module.getItemBySlot(bridge, player, slot)
            end
        end

        return player
    end

    return module
end)
