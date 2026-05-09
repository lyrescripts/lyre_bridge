local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Customize this function
    return false
end

---init
---@description Initializes the framework bridge
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---getPlayerFromId
---@description Gets a player object with helper methods from their server ID
---@param playerId number The player's server ID
---@return table|boolean Player object with methods or false if not found
---@public
function bridge:getPlayerFromId(playerId)
	-- Edit this function to match your framework's functions

	local player = {}

	player.getIdentifier = function() end

	player.showNotification = function(message) end

	player.getAccount = function(account) end

	player.removeAccountMoney = function(account, amount) end

	player.addAccountMoney = function(account, amount) end

	player.getName = function() end

	player.addItem = function(itemName, count, metadata) end

	player.addAmmo = function(ammoItem, weaponName, amount) end

	player.canCarryItem = function(itemName, count)
		-- Return true by default if your framework doesn't track inventory weight.
		return true
	end

	player.removeItem = function(itemName, count) end

	player.hasItem = function(itemName, count) end

	player.getItemCount = function(itemName) end

	return player
end

---getIdFromIdentifier
---@description Gets a player's server ID from their identifier
---@param identifier string The player's identifier
---@return number|boolean Server ID or false if not found
---@public
function bridge:getIdFromIdentifier(identifier)
	-- Edit this function to match your framework's functions
end
