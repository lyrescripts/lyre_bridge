-- Example: register SQL for a third-party resource.
--[[
LyreBridge.registerResource("my_resource", {
    path = "custom/resources/my_resource",
    sql = {
        files = {
            { id = "main", path = "sql/my_resource.sql", required = true, order = 10 },
        },
        frameworkFiles = {
            ESX = {
                { id = "esx_items", path = "sql/my_resource_esx.sql", order = 20 },
            },
        },
    },
})
]]
