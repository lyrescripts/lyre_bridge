local bridge = LyreBridge.bridgeCandidate("ESX")

---expressRefillAction
---@param stationId string
---@param water number
---@param soap number
---@param wax number
---@param maxWater number
---@param maxSoap number
---@param maxWax number
---@param stocks table
---@return void
---@public
function bridge:expressRefillAction(stationId, water, soap, wax, maxWater, maxSoap, maxWax, stocks)
	-- Fill this function if you want to customize the express refill action
	-- If you want to use this, you have to put the config Config.expressRefillAction to "custom"
end

---customRefillFunction
---@param stationId string
---@param water number
---@param soap number
---@param wax number
---@param maxWater number
---@param maxSoap number
---@param maxWax number
---@param stocks table
---@return void
---@public
function bridge:customRefillFunction(stationId, water, soap, wax, maxWater, maxSoap, maxWax, stocks)
	-- Fill this function if you want to customize the refill action
	-- If you want to use this, you have to put the config Config.refillAction to "custom"
end
