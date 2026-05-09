local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Customize this function
    return false
end

---init
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---getPlayerFromId
---@param playerId number
---@return table
---@public
function bridge:getPlayerFromId(playerId)
	local player = {}

	player.showNotification = function(message)
		-- Customize this function
	end

	player.getAccount = function(account)
		-- Customize this function
		return 0
	end

	player.removeAccountMoney = function(account, amount)
		-- Customize this function
	end

	player.addAccountMoney = function(account, amount)
		-- Customize this function
	end

	return player
end
