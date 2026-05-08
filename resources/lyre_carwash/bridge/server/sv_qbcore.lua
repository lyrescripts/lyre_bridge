_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qb-core")
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qb-core"]:GetCoreObject()
end



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
