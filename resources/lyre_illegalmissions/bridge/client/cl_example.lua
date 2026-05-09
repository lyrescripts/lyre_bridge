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

---getAccount
---@param accountName string
---@return number
---@public
function bridge:getAccount(accountName)
	-- Customize this function
	return 0
end

---alert
---@param jobName string
---@param coords table
---@param radius number
---@param title string
---@param description string
---@return void
---@public
function bridge:alert(jobName, coords, radius, title, description)
	self:showNotification(description)
	local alpha = 250
	local blip = AddBlipForRadius(coords.x, coords.y, coords.z, radius or 50.0)

	-- Radius blip settings
	SetBlipHighDetail(blip, true)
	SetBlipColour(blip, 1)
	SetBlipAlpha(blip, alpha)
	SetBlipAsShortRange(blip, true)

	while alpha ~= 0 do
		Citizen.Wait(500)
		alpha = alpha - 1
		SetBlipAlpha(blip, alpha)

		if alpha == 0 then
			RemoveBlip(blip)
			return
		end
	end
end
