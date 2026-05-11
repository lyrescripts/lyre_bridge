local provider = LyreBridge.registerProvider("server", "vehicles", "default", 100)

function provider:detect()
    return true
end

--- Generate a random plate. `format` is an optional template string where:
---   * `A` is replaced by a random uppercase letter
---   * any digit is replaced by a random digit 0-9
---   * `^X` keeps `X` literal
---   * any other character is kept as-is
--- Length is capped to 8 characters. When `format` is nil or empty, a random
--- 8-character alphanumeric plate is returned.
function provider:generateRandomPlate(format)
    if type(format) == "string" and format ~= "" then
        local plate = ""
        local literalNext = false

        for i = 1, #format do
            local c = string.sub(format, i, i)

            if literalNext then
                plate = plate .. c
                literalNext = false
            elseif c == "^" then
                literalNext = true
            elseif c == "A" then
                plate = plate .. string.char(math.random(65, 90))
            elseif string.match(c, "%d") then
                plate = plate .. tostring(math.random(0, 9))
            else
                plate = plate .. c
            end

            if #plate >= 8 then break end
        end

        if plate ~= "" then
            return string.upper(string.sub(plate, 1, 8))
        end
    end

    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    for _ = 1, 8 do
        local idx = math.random(1, #chars)
        plate = plate .. string.sub(chars, idx, idx)
    end
    return plate
end
