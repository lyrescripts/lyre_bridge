_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qbx_core")
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qbx_core"]
end

---applyVehicleProperties
---@param vehicle number
---@param properties table
---@return void
---@public
function bridge:applyVehicleProperties(vehicle, properties)
	if lib and type(lib.setVehicleProperties) == "function" then
		lib.setVehicleProperties(vehicle, properties)
	end

	-- VehicleDeformation integration
	if LyreBridge.isStarted("VehicleDeformation") then
		local deformation = properties["lyre_garage-deformation"]
		if deformation then
			exports["VehicleDeformation"]:SetVehicleDeformation(vehicle, deformation)
		end
	end
end

---getVehicleProperties
---@param vehicle number
---@return table
---@public
function bridge:getVehicleProperties(vehicle)
	local properties = {}

	if lib and type(lib.getVehicleProperties) == "function" then
		properties = lib.getVehicleProperties(vehicle) or {}
	end

	-- VehicleDeformation integration
	if LyreBridge.isStarted("VehicleDeformation") then
		local deformation = exports["VehicleDeformation"]:GetVehicleDeformation(vehicle)
		if deformation then
			properties["lyre_garage-deformation"] = deformation
		end
	end

	return properties
end

---getPlayerJob
---@return table|nil
---@public
function bridge:getPlayerJob()
	if not self.object then
		return nil
	end
	local playerData = self.object:GetPlayerData()
	if not playerData or not playerData.job then
		return nil
	end
	return {
		name = playerData.job.name,
		grade = playerData.job.grade.level,
	}
end

---getPlayerGang
---@return table|nil
---@public
function bridge:getPlayerGang()
	if not self.object then
		return nil
	end
	local playerData = self.object:GetPlayerData()
	if not playerData or not playerData.gang then
		return nil
	end
	return {
		name = playerData.gang.name,
		grade = playerData.gang.grade.level,
	}
end

---isPlayerOnJobDuty
---@return boolean
---@public
function bridge:isPlayerOnJobDuty()
	if not self.object then
		return true
	end
	local playerData = self.object:GetPlayerData()
	if not playerData or not playerData.job then
		return true
	end
	return playerData.job.onduty or false
end

---isPlayerOnGangDuty
---@return boolean
---@public
function bridge:isPlayerOnGangDuty()
	if not self.object then
		return true
	end
	local playerData = self.object:GetPlayerData()
	if not playerData or not playerData.gang then
		return true
	end
	return playerData.gang.onduty or false
end
