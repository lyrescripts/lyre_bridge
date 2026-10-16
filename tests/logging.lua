--[[
     _                       _____           _       _
    | |                     / ____|         (_)     | |      
    | |    _   _ _ __ ___  | (___   ___ _ __ _ _ __ | |_ ___ 
    | |   | | | | '__/ _ \  \___ \ / __| '__| | '_ \| __/ __|
    | |___| |_| | | |  __/  ____) | (__| |  | | |_) | |_\__ \
    |______\__, |_|  \___| |_____/ \___|_|  |_| .__/ \__|___/
            __/ |                             | |            
           |___/                              |_|

]]

-- Run with Lua 5.4 from the resource root. Native calls are stubbed.
local originalPrint = print
local convars, lines, invoking

---@param name string
---@param fallback string
---@return string
function GetConvar(name, fallback)
    return convars[name] or fallback
end

---@return string
function GetCurrentResourceName()
    return "lyre_bridge"
end

---@return string?
function GetInvokingResource()
    return invoking
end

---@param message string
---@return void
function print(message)
    lines[#lines + 1] = message
end

---@param debugConfig? boolean|table<string, boolean>
---@return void
local function reset(debugConfig)
    convars, lines, invoking = {}, {}, "alpha"
    bridge = { core = {}, config = {} }
    LyreBridge = { config = { debug = debugConfig, backgroundBlur = true } }
    convars["lyre_bridge:backgroundBlur"] = "false"
    dofile("engine/configuration.lua")
    dofile("utils/log.lua")
    dofile("utils/setDebug.lua")
    assert(LyreBridge.config.backgroundBlur == false)
end

local settings = { "absent", true, false, {}, { alpha = true, beta = false }, { beta = true } }
local overrides = { "absent", true, false }
local cases = 0

for _, setting in ipairs(settings) do
    for _, global in ipairs(overrides) do
        for _, individual in ipairs(overrides) do
            for _, runtime in ipairs(overrides) do
                if setting == "absent" then reset() else reset(setting) end
                if global ~= "absent" then convars["lyre_bridge:debug"] = tostring(global) end
                if individual ~= "absent" then convars["lyre_bridge:alpha:debug"] = tostring(individual) end
                if runtime ~= "absent" then bridge.core.setDebug(runtime) end

                local expected = setting == true or (type(setting) == "table" and setting.alpha == true)
                if runtime ~= "absent" then expected = runtime end
                if global ~= "absent" then expected = global end
                if individual ~= "absent" then expected = individual end
                assert(bridge.config.get("debug") == expected)
                assert(bridge.config.register({}).debug == expected)

                for _, level in ipairs({ "info", "debug", "INFO", "DeBuG" }) do
                    local before = #lines
                    bridge.core.log(level, "routine")
                    assert(#lines == before + (expected and 1 or 0))
                end
                for _, level in ipairs({ "warning", "warn", "error", "WaRn", "WARNING", "ErRoR" }) do
                    local before = #lines
                    bridge.core.log(level, "visible")
                    assert(#lines == before + 1 and lines[#lines]:find("ALPHA"))
                end
                cases = cases + 1
            end
        end
    end
end

for _, setting in ipairs(settings) do
    if setting == "absent" then reset() else reset(setting) end
    local other = LyreBridge.resolveDebug("beta")
    bridge.core.setDebug(true)
    assert(LyreBridge.resolveDebug("alpha") == true and LyreBridge.resolveDebug("beta") == other)
    bridge.core.setDebug(false)
    assert(LyreBridge.resolveDebug("alpha") == false and LyreBridge.resolveDebug("beta") == other)
    convars["lyre_bridge:debug"] = "true"
    assert(LyreBridge.resolveDebug("alpha") == true)
    convars["lyre_bridge:alpha:debug"] = "false"
    assert(LyreBridge.resolveDebug("alpha") == false and LyreBridge.resolveDebug("beta") == true)
    convars["lyre_bridge:debug"] = "false"
    assert(LyreBridge.resolveDebug("beta") == false)
    invoking = nil
    bridge.core.log("warning", "internal")
    assert(lines[#lines]:find("LYRE_BRIDGE"))
    bridge.core.log("error", "callback", "explicit_owner")
    assert(lines[#lines]:find("EXPLICIT_OWNER"))
end

print = originalPrint
print("Passed " .. cases .. " debug combinations and runtime isolation checks (stubbed natives).")
