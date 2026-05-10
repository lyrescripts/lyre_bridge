LyreBridge.registerProvider("server", "usableItems", {
    name = "ox_inventory",
    resource = "ox_inventory",
    priority = 10,
    isAvailable = function(self, context)
        if not LyreBridge.isStarted("ox_inventory") then
            return false
        end

        if context.object and type(context.object.RegisterUsableItem) == "function" then
            return false
        end

        if context.framework == "ESX" or context.framework == "QBCORE" or context.framework == "QBOX" then
            return false
        end

        return true
    end,
    register = function(self, context)
        local ok, hook = pcall(function()
            return exports.ox_inventory:registerHook("usingItem", function(payload)
                if payload and payload.source and payload.itemName == context.itemName then
                    context.callback(payload.source, payload)
                end
            end, {
                itemFilter = {
                    [context.itemName] = true,
                },
            })
        end)

        if not ok then
            return false, hook
        end

        return true, hook ~= nil
    end,
})
