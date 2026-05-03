_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("qbx_core") == "started"
end

local bridge = _G.bridge[this]
local playerSourceByIdentifierCache = {
	lastUpdate = 0,
	ttl = 1000,
	values = {},
}

local function invalidatePlayerIdentifierCache()
	playerSourceByIdentifierCache.lastUpdate = 0
	playerSourceByIdentifierCache.values = {}
end

local function getPlayerSourcesByIdentifier(qboxObject)
	local now = GetGameTimer()
	if now - playerSourceByIdentifierCache.lastUpdate < playerSourceByIdentifierCache.ttl then
		return playerSourceByIdentifierCache.values
	end

	local values = {}
	local players = qboxObject:GetQBPlayers()

	for _, qbPlayer in pairs(players) do
		local playerData = qbPlayer.PlayerData
		if playerData and playerData.citizenid and playerData.source then
			values[playerData.citizenid] = playerData.source
		end
	end

	playerSourceByIdentifierCache.values = values
	playerSourceByIdentifierCache.lastUpdate = now

	return values
end

AddEventHandler("playerDropped", invalidatePlayerIdentifierCache)
RegisterNetEvent("QBCore:Server:OnPlayerLoaded", invalidatePlayerIdentifierCache)

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qbx_core"]
end

---getPlayerFromId
---@param playerId number
---@return table
---@public
function bridge:getPlayerFromId(playerId)
	local player = self.object:GetPlayer(playerId)

	if not player then
		return false
	end

	local _player = {}

	_player.source = playerId

	_player.getIdentifier = function()
		return player.PlayerData.citizenid
	end

	_player.getName = function()
		local firstname = player.PlayerData.charinfo.firstname or ""
		local lastname = player.PlayerData.charinfo.lastname or ""
		return firstname .. " " .. lastname
	end

	_player.showNotification = function(message)
		self.object:Notify(playerId, message or "", "success", 5000)
	end

	_player.getAccount = function(account)
		if not account then
			return
		end
		local accounts = player.PlayerData.money
		if account == "money" then
			return { money = accounts.cash }
		elseif account == "bank" then
			return { money = accounts.bank }
		elseif account == "black_money" then
			return { money = accounts.crypto }
		else
			return
		end
	end

	_player.removeAccountMoney = function(account, amount)
		if not account or not amount then
			return
		end
		if account == "money" then
			player.Functions.RemoveMoney("cash", amount, "")
		elseif account == "bank" then
			player.Functions.RemoveMoney("bank", amount, "")
		elseif account == "black_money" then
			player.Functions.RemoveMoney("crypto", amount, "")
		else
			return
		end
	end

	_player.addAccountMoney = function(account, amount)
		if not account or not amount then
			return
		end
		if account == "money" then
			player.Functions.AddMoney("cash", amount, "")
		elseif account == "bank" then
			player.Functions.AddMoney("bank", amount, "")
		elseif account == "black_money" then
			player.Functions.AddMoney("crypto", amount, "")
		else
			return
		end
	end

	_player.getJob = function()
		return player.PlayerData.job.name
	end

	_player.getJobRank = function()
		return player.PlayerData.job.grade.level
	end

	_player.getGang = function()
		return player.PlayerData.gang.name
	end

	_player.getGangRank = function()
		return player.PlayerData.gang.grade.level
	end

	_player.getAdminRank = function()
		return self.object:GetGroups(playerId) or {}
	end

	return _player
end

---isVehicleOwned
---@param plate string
---@return boolean
---@public
function bridge:isVehicleOwned(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.scalar.await("SELECT 1 FROM `player_vehicles` WHERE plate = ? LIMIT 1", { normalizedPlate })

	if result then
		return true
	else
		return false
	end
end

---retrieveVehicles
---@param type string
---@param owner string
---@return table
---@public
function bridge:retrieveVehicles(type, owner)
	local typeFilter = ""
	if type == "job" then
		typeFilter = " AND pv.`lyre_garage-job_vehicle` = 1"
	elseif type == "gang" then
		typeFilter = " AND pv.`lyre_garage-gang_vehicle` = 1"
	elseif type == "player" then
		typeFilter = " AND (pv.`lyre_garage-job_vehicle` IS NULL OR pv.`lyre_garage-job_vehicle` != 1) AND (pv.`lyre_garage-gang_vehicle` IS NULL OR pv.`lyre_garage-gang_vehicle` != 1)"
	end

	local selectColumns = [[
		pv.`lyre_garage-name`,
		pv.plate,
		pv.mods,
		pv.`lyre_garage-location`,
		pv.`lyre_garage-location_name`,
		pv.`lyre_garage-job_vehicle`,
		pv.`lyre_garage-gang_vehicle`,
		pv.`lyre_garage-job_rank`,
		pv.`lyre_garage-gang_rank`,
		pv.`lyre_garage-impound_fee`,
		pv.`lyre_garage-allow_owner_retrieve`,
		pv.`lyre_garage-impound_min_retrieve_date`,
		pv.`lyre_garage-impound_reason`,
		pv.`lyre_garage-impounded_by`,
		pv.`lyre_garage-impounded_at`,
		pv.`lyre_garage-fuel`,
		pv.citizenid,
		pv.license
	]]

	local query = string.format(
		[[
		SELECT %s,
			NULL as owner_firstname,
			NULL as owner_lastname,
			1 as is_owner
		FROM `player_vehicles` pv
		WHERE (pv.citizenid = ? OR pv.license = ?)%s
		UNION ALL
		SELECT %s,
			JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) as owner_firstname,
			JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) as owner_lastname,
			0 as is_owner
		FROM `lyre_garage-shared_access` sa
		INNER JOIN `player_vehicles` pv ON pv.plate = sa.plate
		LEFT JOIN `players` p ON pv.citizenid = p.citizenid
		WHERE sa.shared_with_identifier = ? AND (pv.citizenid IS NULL OR pv.citizenid != ?) AND (pv.license IS NULL OR pv.license != ?)%s
		]],
		selectColumns,
		typeFilter,
		selectColumns,
		typeFilter
	)

	local response = MySQL.query.await(query, { owner, owner, owner, owner, owner })

	if response then
		local vehicles = {}

		for i = 1, #response do
			local row = response[i]
			local canPass = true

			local isJobVehicle = (row["lyre_garage-job_vehicle"] == 1 or row["lyre_garage-job_vehicle"] == true)
			local isGangVehicle = (row["lyre_garage-gang_vehicle"] == 1 or row["lyre_garage-gang_vehicle"] == true)

			if type == "job" and not isJobVehicle then
				canPass = false
			end
			if type == "gang" and not isGangVehicle then
				canPass = false
			end
			if type == "player" and (isJobVehicle or isGangVehicle) then
				canPass = false
			end

			if canPass then
				local isOwner = (row.is_owner == 1 or row.is_owner == true)

				local vehicleData = {
					name = row["lyre_garage-name"],
					plate = row.plate,
					vehicle = json.decode(row.mods or "{}"),
					location = row["lyre_garage-location"],
					locationId = row["lyre_garage-location_name"],
					isJobVehicle = isJobVehicle,
					isGangVehicle = isGangVehicle,
					jobRank = row["lyre_garage-job_rank"],
					gangRank = row["lyre_garage-gang_rank"],
					impoundFee = row["lyre_garage-impound_fee"],
					allowOwnerRetrieve = row["lyre_garage-allow_owner_retrieve"],
					impoundMinRetrieveDate = row["lyre_garage-impound_min_retrieve_date"],
					impoundReason = row["lyre_garage-impound_reason"],
					impoundedBy = row["lyre_garage-impounded_by"],
					impoundedAt = row["lyre_garage-impounded_at"],
					fuel = row["lyre_garage-fuel"] or 100.0,
					isOwner = isOwner,
					ownerIdentifier = row.citizenid,
				}

				if not isOwner then
					-- Try to get name from online player first (more up-to-date)
					local onlineOwner = self:getPlayerFromIdentifier(row.citizenid)
					if onlineOwner then
						vehicleData.ownerName = onlineOwner.getName()
					elseif row.owner_firstname and row.owner_lastname then
						-- Use pre-fetched name from JOIN
						vehicleData.ownerName = row.owner_firstname .. " " .. row.owner_lastname
					else
						vehicleData.ownerName = "Unknown"
					end
				end

				table.insert(vehicles, vehicleData)
			end
		end

		return vehicles
	else
		return {}
	end
end

---checkVehicleOwnership
---@param plate string
---@param owner string
---@return boolean
---@public
function bridge:checkVehicleOwnership(plate, owner)
	local normalizedPlate = trim(plate)
	local result = MySQL.scalar.await("SELECT 1 FROM `player_vehicles` WHERE plate = ? AND (citizenid = ? OR license = ?) LIMIT 1", { normalizedPlate, owner, owner })

	if result then
		return true
	else
		return false
	end
end

---getVehicleOwner
---@param plate string
---@return string|nil
---@public
function bridge:getVehicleOwner(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.single.await("SELECT citizenid, license FROM `player_vehicles` WHERE plate = ?", { normalizedPlate })
	if result then
		return result.citizenid or result.license
	end
	return nil
end

---changeVehicleOwner
---@param plate string
---@param newOwner string
---@param newOwnerType string
---@return boolean, string|nil
---@public
function bridge:changeVehicleOwner(plate, newOwner, newOwnerType)
	local normalizedPlate = trim(plate)

	if newOwnerType == "player" then
		local query = [[
			UPDATE `player_vehicles` SET citizenid = ?, license = NULL WHERE plate = ?
		]]
		local success, err = MySQL.update.await(query, { newOwner, normalizedPlate })
		if not success then
			return false, err
		end
		return true, nil
	elseif newOwnerType == "job" or newOwnerType == "gang" then
		local query = [[
			UPDATE `player_vehicles` SET license = ?, citizenid = NULL WHERE plate = ?
		]]
		local success, err = MySQL.update.await(query, { newOwner, normalizedPlate })
		if not success then
			return false, err
		end
		return true, nil
	else
		return false, "Invalid owner type"
	end
end

---saveVehicleProperties
---@param plate string
---@param vehicleProperties table
---@return void
---@public
function bridge:saveVehicleProperties(plate, vehicleProperties)
	local normalizedPlate = trim(plate)

	local query = [[
		UPDATE `player_vehicles` SET mods = ?, engine = ?, body = ? WHERE plate = ?
	]]
	-- Fire-and-forget: no need to wait for completion
	MySQL.update(query, {
		json.encode(vehicleProperties),
		vehicleProperties.engineHealth,
		vehicleProperties.bodyHealth,
		normalizedPlate,
	}, function(affectedRows)
		if not affectedRows or affectedRows == 0 then
			log("error", "Failed to update vehicle properties for vehicle with plate " .. plate)
		end
	end)
end

---getVehicleName
---@param plate string
---@return string|nil
---@public
function bridge:getVehicleName(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.scalar.await("SELECT `lyre_garage-name` FROM `player_vehicles` WHERE plate = ?", { normalizedPlate })
	return result
end

---saveVehicleName
---@param plate string
---@param name string
---@return void
---@public
function bridge:saveVehicleName(plate, name)
	local normalizedPlate = trim(plate)
	-- Fire-and-forget: no need to wait for completion
	MySQL.update("UPDATE `player_vehicles` SET `lyre_garage-name` = ? WHERE plate = ?", { name, normalizedPlate })
end

---saveVehicleLocation
---@param plate string
---@param location string
---@param locationName string
---@param callback function|nil
---@return void
---@public
function bridge:saveVehicleLocation(plate, location, locationName, callback)
	local normalizedPlate = trim(plate)
	-- Fire-and-forget by default; callers can pass a callback when ordering matters.
	MySQL.update("UPDATE `player_vehicles` SET `lyre_garage-location` = ?, `lyre_garage-location_name` = ? WHERE plate = ?", { location, locationName, normalizedPlate }, callback)
end

---clearVehicleLocation
---@param plate string
---@return void
---@public
function bridge:clearVehicleLocation(plate)
	local normalizedPlate = trim(plate)
	-- Fire-and-forget: no need to wait for completion
	MySQL.update("UPDATE `player_vehicles` SET `lyre_garage-location` = NULL, `lyre_garage-location_name` = NULL WHERE plate = ?", { normalizedPlate })
end

---saveVehicleImpoundData
---@param plate string
---@param impoundData table
---@return void
---@public
function bridge:saveVehicleImpoundData(plate, impoundData)
	local normalizedPlate = trim(plate)
	-- Fire-and-forget: no need to wait for completion
	MySQL.update(
		[[UPDATE `player_vehicles` SET
			`lyre_garage-location` = ?,
			`lyre_garage-location_name` = ?,
			`lyre_garage-impound_fee` = ?,
			`lyre_garage-allow_owner_retrieve` = ?,
			`lyre_garage-impound_min_retrieve_date` = ?,
			`lyre_garage-impound_reason` = ?,
			`lyre_garage-impounded_by` = ?,
			`lyre_garage-impounded_at` = ?
		WHERE plate = ?]],
		{
			impoundData.location,
			impoundData.locationName,
			impoundData.impoundFee,
			impoundData.allowOwnerRetrieve,
			impoundData.impoundMinRetrieveDate,
			impoundData.impoundReason,
			impoundData.impoundedBy,
			impoundData.impoundedAt,
			normalizedPlate,
		}
	)
end

---clearVehicleImpoundData
---@param plate string
---@return void
---@public
function bridge:clearVehicleImpoundData(plate)
	local normalizedPlate = trim(plate)
	-- Fire-and-forget: no need to wait for completion
	MySQL.update(
		[[UPDATE `player_vehicles` SET
			`lyre_garage-location` = NULL,
			`lyre_garage-location_name` = NULL,
			`lyre_garage-impound_fee` = NULL,
			`lyre_garage-allow_owner_retrieve` = 1,
			`lyre_garage-impound_min_retrieve_date` = NULL,
			`lyre_garage-impound_reason` = NULL,
			`lyre_garage-impounded_by` = NULL,
			`lyre_garage-impounded_at` = NULL
		WHERE plate = ?]],
		{ normalizedPlate }
	)
end

---saveVehicleOwnerType
---@param plate string
---@param isJobVehicle boolean
---@param isGangVehicle boolean
---@param jobRank number|nil
---@param gangRank number|nil
---@return void
---@public
function bridge:saveVehicleOwnerType(plate, isJobVehicle, isGangVehicle, jobRank, gangRank)
	local normalizedPlate = trim(plate)
	-- Fire-and-forget: no need to wait for completion
	MySQL.update(
		[[UPDATE `player_vehicles` SET
			`lyre_garage-job_vehicle` = ?,
			`lyre_garage-gang_vehicle` = ?,
			`lyre_garage-job_rank` = ?,
			`lyre_garage-gang_rank` = ?
		WHERE plate = ?]],
		{
			isJobVehicle and 1 or 0,
			isGangVehicle and 1 or 0,
			jobRank,
			gangRank,
			normalizedPlate,
		}
	)
end

---saveVehicleFuel
---@param plate string
---@param fuel number
---@return void
---@public
function bridge:saveVehicleFuel(plate, fuel)
	local normalizedPlate = trim(plate)
	-- Fire-and-forget: no need to wait for completion
	MySQL.update("UPDATE `player_vehicles` SET `lyre_garage-fuel` = ? WHERE plate = ?", { fuel, normalizedPlate })
end

---getVehicleLocationName
---@param plate string
---@return string|nil
---@public
function bridge:getVehicleLocationName(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.scalar.await("SELECT `lyre_garage-location_name` FROM `player_vehicles` WHERE plate = ?", { normalizedPlate })
	return result
end

---getVehicleJobRank
---@param plate string
---@return number
---@public
function bridge:getVehicleJobRank(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.scalar.await("SELECT `lyre_garage-job_rank` FROM `player_vehicles` WHERE plate = ?", { normalizedPlate })
	return result or 0
end

---getVehicleGangRank
---@param plate string
---@return number
---@public
function bridge:getVehicleGangRank(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.scalar.await("SELECT `lyre_garage-gang_rank` FROM `player_vehicles` WHERE plate = ?", { normalizedPlate })
	return result or 0
end

---countPlayerVehiclesInGarage
---@param owner string
---@param garageId string
---@param excludePlate string|nil
---@param callback function
---@return void
---@public
function bridge:countPlayerVehiclesInGarage(owner, garageId, excludePlate, callback)
	local query = [[
		SELECT COUNT(*) as vehicle_count
		FROM `player_vehicles`
		WHERE `lyre_garage-location_name` = ? AND (citizenid = ? OR license = ?) AND plate != ?
	]]

	MySQL.query(query, { garageId, owner, owner, excludePlate or "" }, function(result)
		if result and result[1] then
			callback(result[1].vehicle_count or 0)
		else
			callback(0)
		end
	end)
end

---countAllVehiclesInGarage
---@param garageId string
---@param excludePlate string|nil
---@param callback function
---@return void
---@public
function bridge:countAllVehiclesInGarage(garageId, excludePlate, callback)
	local query = [[
		SELECT COUNT(*) as vehicle_count
		FROM `player_vehicles`
		WHERE `lyre_garage-location_name` = ? AND plate != ?
	]]

	MySQL.query(query, { garageId, excludePlate or "" }, function(result)
		if result and result[1] then
			callback(result[1].vehicle_count or 0)
		else
			callback(0)
		end
	end)
end

---giveVehicle
---@param owner string The owner identifier (player identifier, job name, or gang name)
---@param vehicleModel string
---@param plate string
---@param isJobVehicle boolean
---@param isGangVehicle boolean
---@param callback function
---@return void
---@public
function bridge:giveVehicle(owner, vehicleModel, plate, isJobVehicle, isGangVehicle, callback)
	local plate = trim(plate)
	local vehicleProperties = json.encode({
		model = GetHashKey(vehicleModel),
		plate = plate,
		bodyHealth = 1000.0,
		engineHealth = 1000.0,
		tankHealth = 1000.0,
		fuelLevel = 100.0,
		dirtLevel = 0.0,
	})

	local insertQuery
	local params

	if isJobVehicle or isGangVehicle then
		insertQuery = [[
			INSERT INTO `player_vehicles` (license, vehicle, hash, mods, plate, fuel, engine, body, state, `lyre_garage-job_vehicle`, `lyre_garage-gang_vehicle`, `lyre_garage-fuel`)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 100.00)
		]]
		params = { owner, vehicleModel, GetHashKey(vehicleModel), vehicleProperties, plate, 100, 1000.0, 1000.0, 1, isJobVehicle and 1 or 0, isGangVehicle and 1 or 0 }
	else
		insertQuery = [[
			INSERT INTO `player_vehicles` (citizenid, vehicle, hash, mods, plate, fuel, engine, body, state, `lyre_garage-job_vehicle`, `lyre_garage-gang_vehicle`, `lyre_garage-fuel`)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 100.00)
		]]
		params = { owner, vehicleModel, GetHashKey(vehicleModel), vehicleProperties, plate, 100, 1000.0, 1000.0, 1, 0, 0 }
	end

	MySQL.insert(insertQuery, params, function(insertId)
		if insertId then
			callback(true, "Vehicle added successfully")
		else
			callback(false, "Failed to add vehicle to database")
		end
	end)
end

---checkPlateExists
---@param plate string
---@param callback function
---@return void
---@private
function bridge:checkPlateExists(plate, callback)
	local normalizedPlate = trim(plate)
	local query = "SELECT 1 as existing FROM `player_vehicles` WHERE plate = ? LIMIT 1"

	MySQL.query(query, { normalizedPlate }, function(result)
		if result and result[1] then
			callback(true)
		else
			callback(false)
		end
	end)
end

---generateRandomPlate
---@return string
---@private
function bridge:generateRandomPlate()
	local plateFormat = Config.PlateFormat
	if type(plateFormat) == "string" and plateFormat ~= "" then
		local plate = ""
		local nextCharacterIsFixed = false

		for i = 1, #plateFormat do
			local character = string.sub(plateFormat, i, i)

			if nextCharacterIsFixed then
				plate = plate .. character
				nextCharacterIsFixed = false
			elseif character == "^" then
				nextCharacterIsFixed = true
			elseif character == "A" then
				plate = plate .. string.char(math.random(65, 90))
			elseif string.match(character, "%d") then
				plate = plate .. tostring(math.random(0, 9))
			else
				plate = plate .. character
			end

			if string.len(plate) >= 8 then
				break
			end
		end

		if plate ~= "" then
			return string.upper(string.sub(plate, 1, 8))
		end
	end

	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local plate = ""

	for i = 1, 8 do
		local randIndex = math.random(1, #chars)
		plate = plate .. string.sub(chars, randIndex, randIndex)
	end

	return plate
end

---getSpawnedVehicleCount
---@param garageId string
---@param model string
---@param garageType string
---@return number
---@public
function bridge:getSpawnedVehicleCount(garageId, model, garageType)
	-- Use in-memory tracking for spawn garages (server-side only, resets on restart)
	if garageType == "job" then
		if jobSpawnedVehicles[garageId] and jobSpawnedVehicles[garageId][model] then
			return jobSpawnedVehicles[garageId][model]
		end
	elseif garageType == "gang" then
		if gangSpawnedVehicles[garageId] and gangSpawnedVehicles[garageId][model] then
			return gangSpawnedVehicles[garageId][model]
		end
	end
	return 0
end

---incrementSpawnedVehicleCount
---@param garageId string
---@param model string
---@param garageType string
---@return void
---@public
function bridge:incrementSpawnedVehicleCount(garageId, model, garageType)
	-- Use in-memory tracking for spawn garages (server-side only, resets on restart)
	if garageType == "job" then
		if not jobSpawnedVehicles[garageId] then
			jobSpawnedVehicles[garageId] = {}
		end
		if not jobSpawnedVehicles[garageId][model] then
			jobSpawnedVehicles[garageId][model] = 0
		end
		jobSpawnedVehicles[garageId][model] = jobSpawnedVehicles[garageId][model] + 1
	elseif garageType == "gang" then
		if not gangSpawnedVehicles[garageId] then
			gangSpawnedVehicles[garageId] = {}
		end
		if not gangSpawnedVehicles[garageId][model] then
			gangSpawnedVehicles[garageId][model] = 0
		end
		gangSpawnedVehicles[garageId][model] = gangSpawnedVehicles[garageId][model] + 1
	end
end

---decrementSpawnedVehicleCount
---@param garageId string
---@param model string
---@param garageType string
---@return void
---@public
function bridge:decrementSpawnedVehicleCount(garageId, model, garageType)
	-- Use in-memory tracking for spawn garages (server-side only, resets on restart)
	if garageType == "job" then
		if jobSpawnedVehicles[garageId] and jobSpawnedVehicles[garageId][model] then
			jobSpawnedVehicles[garageId][model] = math.max(0, jobSpawnedVehicles[garageId][model] - 1)
		end
	elseif garageType == "gang" then
		if gangSpawnedVehicles[garageId] and gangSpawnedVehicles[garageId][model] then
			gangSpawnedVehicles[garageId][model] = math.max(0, gangSpawnedVehicles[garageId][model] - 1)
		end
	end
end

---deleteVehicleFromFramework
---@param plate string
---@param callback function
---@return void
---@public
function bridge:deleteVehicleFromFramework(plate, callback)
	local normalizedPlate = trim(plate)

	local query = "DELETE FROM `player_vehicles` WHERE plate = ?"
	MySQL.query(query, { normalizedPlate }, function(result)
		if result then
			callback(true, "Vehicle deleted successfully from framework")
		else
			callback(false, "Failed to delete vehicle from framework database")
		end
	end)
end

---onImpoundPayment
---@param playerId number
---@param amount number
---@param paymentMethod string
---@param plate string
---@param impoundId string
---@return void
---@public
function bridge:onImpoundPayment(playerId, amount, paymentMethod, plate, impoundId)
	-- Manage with your framework function if you want to transfer money to society accounts
end

---onVehicleTransferPayment
---@param playerId number
---@param amount number
---@param paymentMethod string
---@param plate string
---@param targetGarageId string
---@return void
---@public
function bridge:onVehicleTransferPayment(playerId, amount, paymentMethod, plate, targetGarageId)
	-- Manage with your framework function if you want to transfer money to society accounts
end

---getVehicleInfo
---@param plate string
---@return table|nil
---@public
function bridge:getVehicleInfo(plate)
	local normalizedPlate = trim(plate)

	local query = [[
		SELECT pv.plate, pv.vehicle, pv.mods, pv.citizenid, p.charinfo
		FROM `player_vehicles` pv
		LEFT JOIN `players` p ON pv.citizenid = p.citizenid
		WHERE pv.plate = ?
	]]

	local result = MySQL.single.await(query, { normalizedPlate })

	if result then
		local vehicleData = json.decode(result.mods or "{}")
		local ownerName = "Unknown"
		if result.charinfo then
			local charinfo = json.decode(result.charinfo)
			if charinfo.firstname and charinfo.lastname then
				ownerName = charinfo.firstname .. " " .. charinfo.lastname
			end
		end

		return {
			plate = result.plate,
			model = vehicleData.model or result.vehicle or "Unknown",
			owner = result.citizenid,
			ownerName = ownerName,
		}
	end

	return nil
end

---changePlate
---@param oldPlate string
---@param newPlate string
---@param callback function
---@return void
---@public
function bridge:changePlate(oldPlate, newPlate, callback)
	local normalizedOldPlate = trim(oldPlate)
	local normalizedNewPlate = trim(newPlate)

	local checkQuery = "SELECT 1 as existing FROM `player_vehicles` WHERE plate = ? LIMIT 1"
	local existingVehicle = MySQL.single.await(checkQuery, { normalizedNewPlate })

	if existingVehicle then
		callback(false, "already_exist")
		return
	end

	local query = "UPDATE `player_vehicles` SET plate = ? WHERE plate = ?"
	MySQL.update(query, { newPlate, normalizedOldPlate }, function(affectedRows)
		if affectedRows > 0 then
			callback(true, "changed_success")
		else
			callback(false, "change_failed")
		end
	end)
end

---getPlayerFromIdentifier
---@param identifier string
---@return table|nil
---@public
function bridge:getPlayerFromIdentifier(identifier)
	local playerSource = getPlayerSourcesByIdentifier(self.object)[identifier]
	if playerSource then
		return self:getPlayerFromId(playerSource)
	end

	return nil
end

---getImpoundedVehicleData
---@param plate string
---@return table|nil
---@public
function bridge:getImpoundedVehicleData(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.single.await(
		[[
		SELECT
			`lyre_garage-location` as location,
			`lyre_garage-location_name` as location_name,
			`lyre_garage-impound_fee` as impound_fee,
			`lyre_garage-allow_owner_retrieve` as allow_owner_retrieve,
			`lyre_garage-impound_min_retrieve_date` as impound_min_retrieve_date,
			`lyre_garage-impound_reason` as impound_reason,
			`lyre_garage-impounded_by` as impounded_by,
			`lyre_garage-impounded_at` as impounded_at
		FROM `player_vehicles`
		WHERE plate = ?
	]],
		{ normalizedPlate }
	)

	return result
end

---isVehicleLockedImpound
---@param plate string
---@return boolean
---@public
function bridge:isVehicleLockedImpound(plate)
	local normalizedPlate = trim(plate)
	local result = MySQL.scalar.await(
		[[
		SELECT 1 FROM `player_vehicles`
		WHERE plate = ?
		AND `lyre_garage-location` = 'impound'
		AND `lyre_garage-allow_owner_retrieve` = 0
		LIMIT 1
	]],
		{ normalizedPlate }
	)

	return result ~= nil
end

---unlockImpoundedVehicle
---@param plate string
---@return boolean
---@public
function bridge:unlockImpoundedVehicle(plate)
	local normalizedPlate = trim(plate)
	local affectedRows = MySQL.update.await(
		[[
		UPDATE `player_vehicles`
		SET `lyre_garage-allow_owner_retrieve` = 1
		WHERE plate = ? AND `lyre_garage-location` = 'impound'
	]],
		{ normalizedPlate }
	)

	return affectedRows and affectedRows > 0
end

---retrieveAllImpoundedVehicles
---@param impoundId string|nil Optional impound ID to filter by (if uniqueImpound is enabled)
---@return table
---@public
function bridge:retrieveAllImpoundedVehicles(impoundId)
	local query = [[
		SELECT
			pv.plate,
			pv.mods as vehicle,
			pv.`lyre_garage-name` as vehicleName,
			pv.`lyre_garage-location` as location,
			pv.`lyre_garage-location_name` as locationId,
			pv.`lyre_garage-impound_fee` as impoundFee,
			pv.`lyre_garage-allow_owner_retrieve` as allowOwnerRetrieve,
			pv.`lyre_garage-impound_min_retrieve_date` as impoundMinRetrieveDate,
			pv.`lyre_garage-impound_reason` as impoundReason,
			pv.`lyre_garage-impounded_by` as impoundedBy,
			pv.`lyre_garage-job_vehicle` as isJobVehicle,
			pv.`lyre_garage-gang_vehicle` as isGangVehicle,
			pv.citizenid as ownerIdentifier,
			JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) as firstname,
			JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) as lastname
		FROM `player_vehicles` pv
		LEFT JOIN `players` p ON pv.citizenid = p.citizenid
		WHERE pv.`lyre_garage-location` = 'impound'
	]]

	local params = {}

	if Config.uniqueImpounds and impoundId then
		query = query .. " AND pv.`lyre_garage-location_name` = ?"
		table.insert(params, impoundId)
	end

	local response = MySQL.query.await(query, params)

	local vehicles = {}
	if response then
		for i = 1, #response do
			local row = response[i]
			local vehicleProps = {}

			if row.vehicle then
				if type(row.vehicle) == "string" then
					vehicleProps = json.decode(row.vehicle) or {}
				elseif type(row.vehicle) == "table" then
					vehicleProps = row.vehicle
				end
			end

			local vehicleName = row.vehicleName
			if not vehicleName or vehicleName == "" then
				vehicleName = "unknown"
			end

			local ownerName = "Unknown"
			if row.firstname and row.lastname then
				ownerName = row.firstname .. " " .. row.lastname
			end

			table.insert(vehicles, {
				plate = row.plate,
				name = vehicleName,
				vehicle = vehicleProps,
				location = row.location,
				locationId = row.locationId,
				impoundFee = row.impoundFee,
				allowOwnerRetrieve = row.allowOwnerRetrieve,
				impoundMinRetrieveDate = row.impoundMinRetrieveDate,
				impoundReason = row.impoundReason,
				impoundedBy = row.impoundedBy,
				ownerIdentifier = row.ownerIdentifier,
				ownerName = ownerName,
				isJobVehicle = row.isJobVehicle == 1,
				isGangVehicle = row.isGangVehicle == 1,
			})
		end
	end

	return vehicles
end

---removeImpoundDateRestriction
---@param plate string
---@return boolean
---@public
function bridge:removeImpoundDateRestriction(plate)
	local normalizedPlate = trim(plate)
	local affectedRows = MySQL.update.await(
		[[
		UPDATE `player_vehicles`
		SET `lyre_garage-impound_min_retrieve_date` = NULL
		WHERE plate = ? AND `lyre_garage-location` = 'impound'
	]],
		{ normalizedPlate }
	)

	return affectedRows and affectedRows > 0
end

---onVehicleDelete
---@param vehicle number The vehicle entity to be deleted
---@return void
---@public
---@description This function is called BEFORE a vehicle is deleted from the world.
---             It handles AdvancedParking integration if the resource is started.
function bridge:onVehicleDelete(vehicle)
	if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
		return
	end

	-- AdvancedParking integration
	if GetResourceState("AdvancedParking") == "started" then
		exports["AdvancedParking"]:DeleteVehicle(vehicle)
	end
end

---getSharedAccessList
---@param plate string
---@return table
---@public
function bridge:getSharedAccessList(plate)
	if not Config.enableSharedVehiclesSystem then
		return {}
	end

	local normalizedPlate = trim(plate)
	local response = MySQL.query.await(
		[[
		SELECT sa.shared_with_identifier,
		JSON_EXTRACT(p.charinfo, '$.firstname') as firstname,
		JSON_EXTRACT(p.charinfo, '$.lastname') as lastname
		FROM `lyre_garage-shared_access` sa
		LEFT JOIN `players` p ON sa.shared_with_identifier = p.citizenid
		WHERE sa.plate = ?
		]],
		{ normalizedPlate }
	)

	if response then
		local sharedPlayers = {}
		for i = 1, #response do
			local row = response[i]
			local playerName = "Unknown"

			local onlinePlayer = self:getPlayerFromIdentifier(row.shared_with_identifier)
			if onlinePlayer then
				playerName = onlinePlayer.getName()
			elseif row.firstname and row.lastname then
				local firstname = string.gsub(row.firstname or "", '"', "")
				local lastname = string.gsub(row.lastname or "", '"', "")
				playerName = firstname .. " " .. lastname
			end

			table.insert(sharedPlayers, {
				identifier = row.shared_with_identifier,
				name = playerName,
			})
		end
		return sharedPlayers
	else
		return {}
	end
end

---retrievePlayerImpoundedVehicles
---@param playerIdentifier string
---@param jobName string|nil
---@param gangName string|nil
---@return table
---@public
---@description Retrieves all impounded vehicles for a player in a single optimized query (personal + job + gang)
function bridge:retrievePlayerImpoundedVehicles(playerIdentifier, jobName, gangName)
	local query = [[
		SELECT
			pv.plate,
			pv.mods as vehicle,
			pv.citizenid,
			pv.license,
			pv.`lyre_garage-name` as vehicleName,
			pv.`lyre_garage-location` as location,
			pv.`lyre_garage-location_name` as locationId,
			pv.`lyre_garage-impound_fee` as impoundFee,
			pv.`lyre_garage-allow_owner_retrieve` as allowOwnerRetrieve,
			pv.`lyre_garage-impound_min_retrieve_date` as impoundMinRetrieveDate,
			pv.`lyre_garage-impound_reason` as impoundReason,
			pv.`lyre_garage-impounded_by` as impoundedBy,
			pv.`lyre_garage-job_vehicle` as isJobVehicle,
			pv.`lyre_garage-gang_vehicle` as isGangVehicle,
			pv.`lyre_garage-fuel` as fuel
		FROM `player_vehicles` pv
		WHERE pv.`lyre_garage-location` = 'impound'
		AND (
			(pv.citizenid = ? AND pv.`lyre_garage-job_vehicle` = 0 AND pv.`lyre_garage-gang_vehicle` = 0)
	]]

	local params = { playerIdentifier }

	if jobName then
		query = query .. " OR (pv.license = ? AND pv.`lyre_garage-job_vehicle` = 1)"
		table.insert(params, jobName)
	end

	if gangName then
		query = query .. " OR (pv.license = ? AND pv.`lyre_garage-gang_vehicle` = 1)"
		table.insert(params, gangName)
	end

	query = query .. ")"

	local response = MySQL.query.await(query, params)

	local vehicles = {}
	if response then
		for i = 1, #response do
			local row = response[i]
			local vehicleProps = {}

			if row.vehicle then
				if type(row.vehicle) == "string" then
					vehicleProps = json.decode(row.vehicle) or {}
				elseif type(row.vehicle) == "table" then
					vehicleProps = row.vehicle
				end
			end

			local vehicleName = row.vehicleName
			if not vehicleName or vehicleName == "" then
				vehicleName = "unknown"
			end

			local isJobVehicle = (row.isJobVehicle == 1 or row.isJobVehicle == true)
			local isGangVehicle = (row.isGangVehicle == 1 or row.isGangVehicle == true)

			table.insert(vehicles, {
				plate = row.plate,
				name = vehicleName,
				vehicle = vehicleProps,
				location = row.location,
				locationId = row.locationId,
				impoundFee = row.impoundFee,
				allowOwnerRetrieve = row.allowOwnerRetrieve,
				impoundMinRetrieveDate = row.impoundMinRetrieveDate,
				impoundReason = row.impoundReason,
				impoundedBy = row.impoundedBy,
				isJobVehicle = isJobVehicle,
				isGangVehicle = isGangVehicle,
				fuel = row.fuel or 100.0,
			})
		end
	end

	return vehicles
end
