_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("qb-core") == "started"
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

---applyVehicleProperties
---@param vehicle number
---@param properties table
---@return void
---@public
function bridge:applyVehicleProperties(vehicle, properties)
	self.object.Functions.SetVehicleProperties(vehicle, properties)

	-- VehicleDeformation integration
	if GetResourceState("VehicleDeformation") == "started" then
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
	local properties = self.object.Functions.GetVehicleProperties(vehicle)

	-- VehicleDeformation integration
	if GetResourceState("VehicleDeformation") == "started" then
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
	local playerData = self.object.Functions.GetPlayerData()
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
	local playerData = self.object.Functions.GetPlayerData()
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
	local playerData = self.object.Functions.GetPlayerData()
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
	local playerData = self.object.Functions.GetPlayerData()
	if not playerData or not playerData.gang then
		return true
	end
	return playerData.gang.onduty or false
end
