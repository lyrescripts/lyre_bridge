local Core = LyreBridge
function Core.applyModuleDefaults(bridge, context)
    if type(bridge) ~= "table" or type(context) ~= "table" then
        return bridge
    end

    if context.side == "client" then
        if type(bridge.showNotification) ~= "function" then
            function bridge:showNotification(message, notificationType, duration)
                local module = Core.getModule("client", "notifications")
                return module and module.show(message, notificationType, duration, self)
            end
        end

        if type(bridge.showHelpNotification) ~= "function" then
            function bridge:showHelpNotification(message)
                local module = Core.getModule("client", "notifications")
                return module and module.help(message, self)
            end
        end

        if type(bridge.targetAddLocalEntity) ~= "function" then
            function bridge:targetAddLocalEntity(entity, options)
                local module = Core.getModule("client", "target")
                return module and module.addLocalEntity(entity, options)
            end
        end

        if type(bridge.targetRemoveEntity) ~= "function" then
            function bridge:targetRemoveEntity(entity, optionNames)
                local module = Core.getModule("client", "target")
                return module and module.removeEntity(entity, optionNames)
            end
        end

        if type(bridge.targetRemoveLocalEntity) ~= "function" then
            function bridge:targetRemoveLocalEntity(entity, optionNames)
                local module = Core.getModule("client", "target")
                return module and module.removeEntity(entity, optionNames)
            end
        end

        if type(bridge.targetAddSphereZone) ~= "function" then
            function bridge:targetAddSphereZone(...)
                local module = Core.getModule("client", "target")
                return module and module.addSphereZone(...)
            end
        end

        if type(bridge.targetRemoveZone) ~= "function" then
            function bridge:targetRemoveZone(id)
                local module = Core.getModule("client", "target")
                return module and module.removeZone(id)
            end
        end

        if type(bridge.giveVehicleKeys) ~= "function" then
            function bridge:giveVehicleKeys(...)
                local module = Core.getModule("client", "vehicleKeys")
                return module and module.give(...)
            end
        end

        if type(bridge.removeVehicleKeys) ~= "function" then
            function bridge:removeVehicleKeys(plate, options)
                local module = Core.getModule("client", "vehicleKeys")
                return module and module.remove(plate, options)
            end
        end

        if type(bridge.setFuel) ~= "function" then
            function bridge:setFuel(vehicleOrNetId, fuel)
                local module = Core.getModule("client", "fuel")
                return module and module.set(vehicleOrNetId, fuel)
            end
        end

        if type(bridge.getFuel) ~= "function" then
            function bridge:getFuel(vehicleOrNetId)
                local module = Core.getModule("client", "fuel")
                return module and module.get(vehicleOrNetId)
            end
        end

        if type(bridge.progress) ~= "function" then
            function bridge:progress(...)
                local module = Core.getModule("client", "progress")
                return module and module.run(...)
            end
        end

        if type(bridge.hasItem) ~= "function" then
            function bridge:hasItem(itemName, amount)
                local module = Core.getModule("client", "inventory")
                return module and module.hasItem(self, itemName, amount) or false
            end
        end

        if type(bridge.sendDispatchAlert) ~= "function" then
            function bridge:sendDispatchAlert(payload, options)
                local module = Core.getModule("client", "dispatch")
                return module and module.send(payload, options) or false
            end
        end
    elseif context.side == "server" then
        if type(bridge.ensureSql) ~= "function" then
            function bridge:ensureSql(resourceName, options)
                local module = Core.getModule("server", "sql")
                return module and module.ensure(resourceName, options)
            end
        end

        if type(bridge.getPlayerFromId) ~= "function" then
            function bridge:getPlayerFromId(playerId)
                local module = Core.getModule("server", "players")
                return module and module.getPlayerFromId(self, playerId)
            end
        end

        if type(bridge.getIdFromIdentifier) ~= "function" then
            function bridge:getIdFromIdentifier(identifier)
                local module = Core.getModule("server", "players")
                return module and module.getIdFromIdentifier(self, identifier)
            end
        end

        if type(bridge.getPlayerFromIdentifier) ~= "function" then
            function bridge:getPlayerFromIdentifier(identifier)
                local module = Core.getModule("server", "players")
                return module and module.getPlayerFromIdentifier(self, identifier)
            end
        end

        if type(bridge.removePlayerMoney) ~= "function" then
            function bridge:removePlayerMoney(playerId, account, amount)
                local module = Core.getModule("server", "players")
                return module and module.removePlayerMoney(self, playerId, account, amount)
            end
        end

        if type(bridge.getPlayerIdentifier) ~= "function" then
            function bridge:getPlayerIdentifier(playerId)
                local module = Core.getModule("server", "players")
                return module and module.getPlayerIdentifier(self, playerId)
            end
        end

        if type(bridge.getIdentifierFromSource) ~= "function" then
            function bridge:getIdentifierFromSource(playerId)
                local module = Core.getModule("server", "players")
                return module and module.getIdentifierFromSource(self, playerId)
            end
        end

        if type(bridge.getPlayerName) ~= "function" then
            function bridge:getPlayerName(playerId)
                local module = Core.getModule("server", "players")
                return module and module.getPlayerName(self, playerId)
            end
        end

        if type(bridge.getPlayerDisplayName) ~= "function" then
            function bridge:getPlayerDisplayName(playerId)
                local module = Core.getModule("server", "players")
                return module and module.getPlayerDisplayName(self, playerId)
            end
        end

        if type(bridge.showNotification) ~= "function" then
            function bridge:showNotification(playerId, message, notificationType, duration)
                local module = Core.getModule("server", "players")
                return module and module.showNotification(self, playerId, message, notificationType, duration)
            end
        end

        if type(bridge.hasLicense) ~= "function" then
            function bridge:hasLicense(playerId, licenseType, callback)
                local module = Core.getModule("server", "licenses")
                return module and module.hasLicense(self, playerId, licenseType, callback) or false
            end
        end

        if type(bridge.grantLicense) ~= "function" then
            function bridge:grantLicense(playerId, licenseType)
                local module = Core.getModule("server", "licenses")
                return module and module.grantLicense(self, playerId, licenseType) or false
            end
        end

        if type(bridge.registerUsableItem) ~= "function" then
            function bridge:registerUsableItem(itemName, callback)
                local module = Core.getModule("server", "usableItems")
                return module and module.register(self, itemName, callback)
            end
        end

        if type(bridge.getSocietyMoney) ~= "function" then
            function bridge:getSocietyMoney(jobName)
                local module = Core.getModule("server", "society")
                return module and module.getMoney(self, jobName) or 0
            end
        end

        if type(bridge.removeSocietyMoney) ~= "function" then
            function bridge:removeSocietyMoney(jobName, amount)
                local module = Core.getModule("server", "society")
                return module and module.removeMoney(self, jobName, amount) or false
            end
        end

        if type(bridge.updateOfflinePlayerAccount) ~= "function" then
            function bridge:updateOfflinePlayerAccount(identifier, account, amount)
                local module = Core.getModule("server", "offlineAccounts")
                return module and module.update(self, identifier, account, amount) or false
            end
        end

        if type(bridge.inventorySupportsMetadata) ~= "function" then
            function bridge:inventorySupportsMetadata()
                local module = Core.getModule("server", "inventory")
                return module and module.supportsMetadata(self) or false
            end
        end

        if type(bridge.sendDispatchAlert) ~= "function" then
            function bridge:sendDispatchAlert(payload, options)
                local module = Core.getModule("server", "dispatch")
                return module and module.send(payload, options) or false
            end
        end

        if type(bridge.getVehicleMileage) ~= "function" then
            function bridge:getVehicleMileage()
                return nil, nil, nil
            end
        end

        if type(bridge.getPlayerFromId) == "function" and not bridge.__lyrePlayerEnriched then
            local originalGetPlayerFromId = bridge.getPlayerFromId

            bridge.getPlayerFromId = function(self, playerId)
                local player = originalGetPlayerFromId(self, playerId)
                if type(player) == "table" then
                    local module = Core.getModule("server", "inventory")
                    if module and type(module.enrichPlayer) == "function" then
                        module.enrichPlayer(self, player)
                    end
                end

                return player
            end

            bridge.__lyrePlayerEnriched = true
        end
    end

    return bridge
end
