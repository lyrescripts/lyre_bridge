-- Example: resource SQL is auto-discovered when files follow the convention.
--[[
LyreBridge.registerResource("my_resource")

-- Discovered automatically:
-- resources/my_resource/sql/import.sql
-- resources/my_resource/sql/import_esx.sql
-- resources/my_resource/sql/import_qb.sql

-- Use an explicit declaration only for uncommon paths:
LyreBridge.registerResource("custom_resource", {
    sql = {
        files = {
            { id = "custom_schema", path = "sql/custom_schema.sql", required = true, order = 10 },
        },
    },
})
]]
