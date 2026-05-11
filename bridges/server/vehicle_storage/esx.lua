local provider = LyreBridge.registerProvider("server", "vehicle_storage", "esx", 10)

function provider:detect()
    return bridge.core:isStarted("es_extended")
end

function provider:getTableName()
    return "owned_vehicles"
end

function provider:exists(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" then return false end
    return MySQL.scalar.await("SELECT 1 FROM `owned_vehicles` WHERE plate = ? LIMIT 1", { plate }) ~= nil
end

function provider:getOwner(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    return MySQL.scalar.await("SELECT owner FROM `owned_vehicles` WHERE plate = ?", { plate })
end

function provider:isOwnedBy(plate, owner)
    if not owner then return false end
    return self:getOwner(plate) == owner
end

function provider:setOwner(plate, newOwner)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" or not newOwner then return false end
    local affected = MySQL.update.await("UPDATE `owned_vehicles` SET owner = ? WHERE plate = ?", { newOwner, plate })
    return (affected or 0) > 0
end

function provider:getProperties(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    local raw = MySQL.scalar.await("SELECT vehicle FROM `owned_vehicles` WHERE plate = ?", { plate })
    if not raw then return nil end
    local ok, decoded = pcall(json.decode, raw)
    return ok and decoded or nil
end

function provider:setProperties(plate, properties)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" or type(properties) ~= "table" then return false end
    local affected = MySQL.update.await(
        "UPDATE `owned_vehicles` SET vehicle = ? WHERE plate = ?",
        { json.encode(properties), plate }
    )
    return (affected or 0) > 0
end

function provider:getInfo(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    local row = MySQL.single.await("SELECT plate, owner, vehicle FROM `owned_vehicles` WHERE plate = ?", { plate })
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

function provider:getByOwner(owner)
    if not owner then return {} end
    local rows = MySQL.query.await("SELECT plate, owner, vehicle FROM `owned_vehicles` WHERE owner = ?", { owner })
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

    local affected = MySQL.insert.await(
        "INSERT INTO `owned_vehicles` (owner, plate, vehicle) VALUES (?, ?, ?)",
        { owner, plate, json.encode(properties) }
    )
    return (affected or 0) > 0
end

function provider:delete(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" then return false end
    local affected = MySQL.update.await("DELETE FROM `owned_vehicles` WHERE plate = ?", { plate })
    return (affected or 0) > 0
end

function provider:renamePlate(oldPlate, newPlate)
    oldPlate = oldPlate and oldPlate:gsub("^%s*(.-)%s*$", "%1")
    newPlate = newPlate and newPlate:gsub("^%s*(.-)%s*$", "%1")
    if not oldPlate or oldPlate == "" or not newPlate or newPlate == "" then return false end
    local affected = MySQL.update.await("UPDATE `owned_vehicles` SET plate = ? WHERE plate = ?", { newPlate, oldPlate })
    return (affected or 0) > 0
end
