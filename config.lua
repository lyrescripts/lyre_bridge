LyreBridge = LyreBridge or {}
LyreBridge.config = LyreBridge.config or {}

local config = LyreBridge.config

local function setDefault(key, value)
	if config[key] == nil then
		config[key] = value
	end
end

-- [string] → The locale to use for the bridge. This is the language that will be used for the bridge messages.
setDefault("locale", "en")

-- [string] → The default locale to use if the resource locale is not found.
setDefault("defaultLocale", "en")

-- [string] → The fallback locale to use if neither the resource locale nor the default locale is found.
setDefault("fallbackLocale", "en")

-- [string] → The bridge to use for the framework detection.
-- Available options are "auto_detect", "esx", "qbcore", "qbox", "standalone" or "example".
setDefault("bridge", "auto_detect")

-- [boolean] → If you want the bridge to check for updates on start.
setDefault("checkForUpdates", true)

-- [boolean] → If you want to apply a background blur effect when a menu is opened.
setDefault("backgroundBlur", false)

-- [string] → The interact system to use for world interactions.
-- Available options are "marker" or "target".
setDefault("interactSystem", "marker")

-- [table] → Default config overrides applied per resource.
-- Use this to override specific config values for a given resource.
config.resourceDefaults = config.resourceDefaults or {
	lyre_illegalmissions = {
		backgroundBlur = true,
	},
}

-- [table] → Convar mappings per resource.
-- Allows resources to read their config values from FiveM convars instead of the config file.
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
