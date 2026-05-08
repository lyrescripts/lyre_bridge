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

---revivePlayer
---@param serverId number The server ID of the player to revive
---@return void
---@public
function bridge:revivePlayer(serverId)
	ExecuteCommand("revive " .. serverId)
end
