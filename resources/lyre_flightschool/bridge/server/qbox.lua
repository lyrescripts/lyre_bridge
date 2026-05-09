local bridge = LyreBridge.bridgeCandidate("QBOX")

---hasLicense
---Checks if a player has a specific license
---@param source number The player source
---@param licenseType string The type of license (plane, heli)
---@param cb function Callback function with result (true/false)
---@return void
---@public
function bridge:hasLicense(source, licenseType, cb)
	local Player = self.object:GetPlayer(source)
	if not Player then
		cb(false)
		return
	end

	-- License mapping for Qbox
	local licenseMap = {
		["plane"] = "fly_plane",
		["heli"] = "fly_heli",
	}

	local license = licenseMap[licenseType]
	if not license then
		cb(false)
		return
	end

	-- Check if player has the license in metadata
	local metadata = Player.PlayerData.metadata
	local hasLicense = metadata.licences and metadata.licences[license] == true
	cb(hasLicense)
end

---grantLicense
---Grants a pilot license to the player
---@param source number The player source
---@param licenseType string The type of license (plane, heli)
---@return boolean success Whether the grant was successful
---@public
function bridge:grantLicense(source, licenseType)
	local Player = self.object:GetPlayer(source)
	if not Player then
		return false
	end

	-- License mapping for Qbox
	local licenseMap = {
		["plane"] = "fly_plane",
		["heli"] = "fly_heli",
	}

	local license = licenseMap[licenseType]
	if not license then
		return false
	end

	-- Check if player already has the license
	local metadata = Player.PlayerData.metadata
	if metadata.licences and metadata.licences[license] then
		return true -- Already has license
	end

	-- Grant the license
	if not metadata.licences then
		metadata.licences = {}
	end
	metadata.licences[license] = true
	Player.Functions.SetMetaData("licences", metadata.licences)
	Player.Functions.Save()
	return true
end
