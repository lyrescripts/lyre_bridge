local provider = LyreBridge.registerProvider("server", "vehicle_storage", "qbox", 5)

function provider:detect()
    return bridge.core.isStarted("qbx_core")
end

function provider:getTableName()
    return "player_vehicles"
end

function provider:exists(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" then return false end
    return bridge.mysql.scalar("SELECT 1 FROM `player_vehicles` WHERE plate = ? LIMIT 1", { plate }) ~= nil
end

function provider:getOwner(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    return bridge.mysql.scalar("SELECT citizenid FROM `player_vehicles` WHERE plate = ?", { plate })
end

function provider:isOwnedBy(plate, owner)
    if not owner then return false end
    return self:getOwner(plate) == owner
end

function provider:setOwner(plate, newOwner)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" or not newOwner then return false end
    local affected = bridge.mysql.update(
        "UPDATE `player_vehicles` SET citizenid = ? WHERE plate = ?",
        { newOwner, plate }
    )
    return (affected or 0) > 0
end

function provider:getProperties(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    local raw = bridge.mysql.scalar("SELECT mods FROM `player_vehicles` WHERE plate = ?", { plate })
    if not raw then return nil end
    local ok, decoded = pcall(json.decode, raw)
    return ok and decoded or nil
end

function provider:setProperties(plate, properties)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" or type(properties) ~= "table" then return false end
    local affected = bridge.mysql.update(
        "UPDATE `player_vehicles` SET mods = ?, engine = ?, body = ? WHERE plate = ?",
        { json.encode(properties), properties.engineHealth or 1000.0, properties.bodyHealth or 1000.0, plate }
    )
    return (affected or 0) > 0
end

function provider:getInfo(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    local row = bridge.mysql.single("SELECT plate, citizenid, mods FROM `player_vehicles` WHERE plate = ?", { plate })
    if not row then return nil end
    local props
    if row.mods then
        local ok, decoded = pcall(json.decode, row.mods)
        props = ok and decoded or nil
    end
    return {
        plate = row.plate,
        owner = row.citizenid,
        properties = props,
    }
end

function provider:getByOwner(owner)
    if not owner then return {} end
    local rows = bridge.mysql.query(
        "SELECT plate, citizenid, mods FROM `player_vehicles` WHERE citizenid = ?",
        { owner }
    )
    local vehicles = {}
    for i = 1, #(rows or {}) do
        local row = rows[i]
        local props
        if row.mods then
            local ok, decoded = pcall(json.decode, row.mods)
            props = ok and decoded or nil
        end
        vehicles[#vehicles + 1] = {
            plate = row.plate,
            owner = row.citizenid,
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

    local affected = bridge.mysql.insert(
        [[INSERT INTO `player_vehicles` (citizenid, plate, vehicle, hash, mods, engine, body)
          VALUES (?, ?, ?, ?, ?, ?, ?)]],
        {
            owner,
            plate,
            model,
            GetHashKey(model),
            json.encode(properties),
            properties.engineHealth or 1000.0,
            properties.bodyHealth or 1000.0,
        }
    )
    return (affected or 0) > 0
end

function provider:delete(plate)
    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1")
    if not plate or plate == "" then return false end
    local affected = bridge.mysql.update("DELETE FROM `player_vehicles` WHERE plate = ?", { plate })
    return (affected or 0) > 0
end

function provider:renamePlate(oldPlate, newPlate)
    oldPlate = oldPlate and oldPlate:gsub("^%s*(.-)%s*$", "%1")
    newPlate = newPlate and newPlate:gsub("^%s*(.-)%s*$", "%1")
    if not oldPlate or oldPlate == "" or not newPlate or newPlate == "" then return false end
    local affected = bridge.mysql.update(
        "UPDATE `player_vehicles` SET plate = ? WHERE plate = ?",
        { newPlate, oldPlate }
    )
    return (affected or 0) > 0
end
