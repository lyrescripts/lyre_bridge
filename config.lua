LyreBridge = LyreBridge or {}
LyreBridge.config = LyreBridge.config or {}

local config = LyreBridge.config

local function setDefault(key, value)
    if config[key] == nil then
        config[key] = value
    end
end

setDefault("locale", "en")
setDefault("defaultLocale", "en")
setDefault("fallbackLocale", "en")
setDefault("bridge", "auto_detect")
setDefault("checkForUpdates", true)
setDefault("backgroundBlur", false)
setDefault("interactSystem", "marker")

config.resourceDefaults = config.resourceDefaults or {
    lyre_illegalmissions = {
        backgroundBlur = true,
    },
}

config.resourceConvars = config.resourceConvars or {
    lyre_illegalmissions = {
        locale = { "lyre_illegalmissions:locale" },
        interactSystem = { "lyre_illegalmissions:target" },
    },
    ["lyre_illegalmissions-atm"] = {
        locale = { "lyre_illegalmissions:locale" },
        interactSystem = { "lyre_illegalmissions:target" },
    },
    ["lyre_illegalmissions-cartheft"] = {
        locale = { "lyre_illegalmissions:locale" },
        interactSystem = { "lyre_illegalmissions:target" },
    },
    ["lyre_illegalmissions-gofast"] = {
        locale = { "lyre_illegalmissions:locale" },
        interactSystem = { "lyre_illegalmissions:target" },
    },
    ["lyre_illegalmissions-moneytruck"] = {
        locale = { "lyre_illegalmissions:locale" },
        interactSystem = { "lyre_illegalmissions:target" },
    },
    ["lyre_illegalmissions-murderer"] = {
        locale = { "lyre_illegalmissions:locale" },
        interactSystem = { "lyre_illegalmissions:target" },
    },
}
