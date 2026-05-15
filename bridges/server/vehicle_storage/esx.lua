local provider = LyreBridge.registerProvider("server", "vehicle_storage", "esx", 10)

---Active when the `es_extended` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
end

---Underlying SQL table holding owned vehicles.
---@return string
function provider:getTableName()
    return "owned_vehicles"
end

---Whether a record exists for the given plate.
---@param plate string
---@return boolean
function provider:exists(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" then return false end
    return bridge.mysql.scalar("SELECT 1 FROM `owned_vehicles` WHERE plate = ? LIMIT 1", { plate }) ~= nil
end

---Identifier of the plate's owner.
---@param plate string
---@return string?
function provider:getOwner(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    return bridge.mysql.scalar("SELECT owner FROM `owned_vehicles` WHERE plate = ?", { plate })
end

---Whether `plate` is currently owned by `owner`.
---@param plate string
---@param owner string
---@return boolean
function provider:isOwnedBy(plate, owner)
    if not owner then return false end
    return self:getOwner(plate) == owner
end

---Transfer ownership of `plate` to `newOwner`.
---@param plate string
---@param newOwner string
---@return boolean
function provider:setOwner(plate, newOwner)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" or not newOwner then return false end
    local affected = bridge.mysql.update("UPDATE `owned_vehicles` SET owner = ? WHERE plate = ?", { newOwner, plate })
    return (affected or 0) > 0
end

---Decoded vehicle properties stored for `plate`.
---@param plate string
---@return table?
function provider:getProperties(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    local raw = bridge.mysql.scalar("SELECT vehicle FROM `owned_vehicles` WHERE plate = ?", { plate })
    if not raw then return nil end
    local ok, decoded = pcall(json.decode, raw)
    return ok and decoded or nil
end

---Persist new vehicle properties for `plate`.
---@param plate string
---@param properties table
---@return boolean
function provider:setProperties(plate, properties)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" or type(properties) ~= "table" then return false end
    local affected = bridge.mysql.update(
        "UPDATE `owned_vehicles` SET vehicle = ? WHERE plate = ?",
        { json.encode(properties), plate }
    )
    return (affected or 0) > 0
end

---Combined owner + properties payload.
---@param plate string
---@return table?
function provider:getInfo(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    local row = bridge.mysql.single("SELECT plate, owner, vehicle FROM `owned_vehicles` WHERE plate = ?", { plate })
    if not row then return nil end
    local props
    if row.vehicle then
        local ok, decoded = pcall(json.decode, row.vehicle)
        props = ok and decoded or nil
    end
    return {
        plate = row.plate,
        owner = row.owner,
        properties = props,
    }
end

---Every vehicle row owned by `owner`.
---@param owner string
---@return table[]
function provider:getByOwner(owner)
    if not owner then return {} end
    local rows = bridge.mysql.query("SELECT plate, owner, vehicle FROM `owned_vehicles` WHERE owner = ?", { owner })
    local vehicles = {}
    for i = 1, #(rows or {}) do
        local row = rows[i]
        local props
        if row.vehicle then
            local ok, decoded = pcall(json.decode, row.vehicle)
            props = ok and decoded or nil
        end
        vehicles[#vehicles + 1] = {
            plate = row.plate,
            owner = row.owner,
            properties = props,
        }
    end
    return vehicles
end

---Insert a new owned vehicle.
---@param owner string
---@param model string
---@param plate string
---@param properties? table Defaults to a brand-new vehicle profile.
---@return boolean
function provider:create(owner, model, plate, properties)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" or not owner or not model then return false end

    properties = properties or {
        model = GetHashKey(model),
        plate = plate,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        tankHealth = 1000.0,
        fuelLevel = 100.0,
        dirtLevel = 0.0,
    }

    local affected = bridge.mysql.insert(
        "INSERT INTO `owned_vehicles` (owner, plate, vehicle) VALUES (?, ?, ?)",
        { owner, plate, json.encode(properties) }
    )
    return (affected or 0) > 0
end

---Drop the owned-vehicle row for `plate`.
---@param plate string
---@return boolean
function provider:delete(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" then return false end
    local affected = bridge.mysql.update("DELETE FROM `owned_vehicles` WHERE plate = ?", { plate })
    return (affected or 0) > 0
end

---Rewrite the plate for an existing record.
---@param oldPlate string
---@param newPlate string
---@return boolean
function provider:renamePlate(oldPlate, newPlate)
    oldPlate = oldPlate and oldPlate:gsub("^%s*(.-)%s*$", "%1")
    newPlate = newPlate and newPlate:gsub("^%s*(.-)%s*$", "%1")
    if not oldPlate or oldPlate == "" or not newPlate or newPlate == "" then return false end
    local affected = bridge.mysql.update("UPDATE `owned_vehicles` SET plate = ? WHERE plate = ?", { newPlate, oldPlate })
    return (affected or 0) > 0
end
