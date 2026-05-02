-- Example: shared webhook helper.
--[[
LyreBridge.registerModule("server", "webhooks", function()
    return {
        send = function(url, title, description)
            PerformHttpRequest(url, function() end, "POST", json.encode({
                embeds = {
                    { title = title, description = description, color = 5793266 },
                },
            }), { ["Content-Type"] = "application/json" })
            return true
        end,
    }
end)
]]
