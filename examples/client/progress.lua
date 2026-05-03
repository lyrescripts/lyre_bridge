-- Example: replace progress with a custom progressbar.
--[[
LyreBridge.registerModule("client", "progress", function()
    return {
        run = function(options)
            if type(options) ~= "table" then
                options = { duration = options }
            end

            return exports["my_progress"]:Start(options.label or "", options.duration or 0)
        end,
    }
end)
]]
