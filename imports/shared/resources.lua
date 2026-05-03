local Core = LyreBridge

local function normalizePath(path)
    return tostring(path or "")
        :gsub("\\", "/")
        :gsub("^%./", "")
        :gsub("/+", "/")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

Core.normalizePath = Core.normalizePath or normalizePath

local function addIssue(target, code, message, context)
    target[#target + 1] = {
        code = code,
        message = message,
        context = context,
    }
end

local function cloneContext(context, extra)
    local cloned = {}

    for key, value in pairs(context or {}) do
        cloned[key] = value
    end

    for key, value in pairs(extra or {}) do
        cloned[key] = value
    end

    return cloned
end

local function resolveResourcePath(resourceName, definition, path, absolute)
    local normalized = normalizePath(path)

    if normalized == "" then
        return ""
    end

    if absolute or normalized:sub(1, #"resources/") == "resources/" then
        return normalized
    end

    return normalizePath((definition.path or ("resources/" .. resourceName)) .. "/" .. normalized)
end

Core.resolveResourcePath = Core.resolveResourcePath or resolveResourcePath

local function resourceFileExists(path)
    if type(LoadResourceFile) ~= "function" then
        return true
    end

    return type(LoadResourceFile("lyre_bridge", path)) == "string"
end

Core.resourceFileExists = Core.resourceFileExists or resourceFileExists

local function loadBridgeRuntimeFile(path, context)
    path = normalizePath(path)

    if path == "" then
        return false, Core.fail("empty_runtime_file_path", "Runtime file path is empty.", context)
    end

    Core._loadedRuntimeFiles = Core._loadedRuntimeFiles or {}
    if Core._loadedRuntimeFiles[path] then
        return true
    end

    if type(LoadResourceFile) ~= "function" then
        Core._loadedRuntimeFiles[path] = true
        return true
    end

    local runtime = LoadResourceFile("lyre_bridge", path)
    if type(runtime) ~= "string" then
        return false, Core.fail("runtime_file_missing", "Runtime file is missing in lyre_bridge.", cloneContext(context, {
            path = path,
        }))
    end

    local fn, err = load(runtime, "@lyre_bridge/" .. path)
    if not fn then
        return false, Core.fail("runtime_file_compile_failed", tostring(err), cloneContext(context, {
            path = path,
        }))
    end

    local ok, result = pcall(fn)
    if not ok then
        return false, Core.fail("runtime_file_load_failed", tostring(result), cloneContext(context, {
            path = path,
        }))
    end

    Core._loadedRuntimeFiles[path] = true
    return true
end

function Core.loadResourceDefinition(resourceName)
    if type(resourceName) ~= "string" or resourceName == "" then
        return false, Core.fail("invalid_resource_name", "Resource definition loading expects a resource name.")
    end

    if Core.resources and Core.resources[resourceName] then
        return true, Core.resources[resourceName]
    end

    local path = normalizePath(("resources/%s/resource.lua"):format(resourceName))
    local ok, err = loadBridgeRuntimeFile(path, {
        resource = resourceName,
        kind = "resource",
    })

    if not ok then
        return false, err
    end

    local definition = Core.resources and Core.resources[resourceName]
    if type(definition) ~= "table" then
        return false, Core.fail("resource_definition_missing", "Resource definition did not register itself.", {
            resource = resourceName,
            path = path,
        })
    end

    return true, definition
end

function Core.loadResourceBridgeFiles(side, resourceName, options)
    options = options or {}
    side = side or "shared"

    local ok, definitionOrError = Core.loadResourceDefinition(resourceName)
    if not ok then
        return false, definitionOrError
    end

    local definition = definitionOrError
    local bridge = definition.bridge
    local files = type(bridge) == "table" and bridge[side] or nil

    if files == nil then
        return true, definition
    end

    if type(files) ~= "table" then
        return false, Core.fail("invalid_bridge_file_list", "Bridge files must be listed in an array.", {
            resource = resourceName,
            side = side,
        })
    end

    for index, file in ipairs(files) do
        if type(file) ~= "string" or file == "" then
            return false, Core.fail("invalid_bridge_file_entry", "Bridge file entries must be non-empty strings.", {
                resource = resourceName,
                side = side,
                index = index,
            })
        end

        local path = resolveResourcePath(resourceName, definition, file)
        local loaded, loadError = loadBridgeRuntimeFile(path, {
            resource = resourceName,
            side = side,
            kind = "bridge",
            index = index,
        })

        if not loaded then
            return false, loadError
        end
    end

    Core.log("debug", "Resource bridge files loaded.", {
        resource = resourceName,
        side = side,
        files = #files,
    })

    return true, definition
end

local function validateFile(summary, path, context)
    if path == "" then
        addIssue(summary.errors, "empty_resource_file_path", "Registered file path is empty.", context)
        return
    end

    if not resourceFileExists(path) then
        addIssue(summary.errors, "resource_file_missing", "Registered file does not exist in lyre_bridge.", cloneContext(context, {
            path = path,
        }))
    end
end

local function validateBridgeFiles(summary, resourceName, definition, side, files)
    if files == nil then
        return
    end

    if type(files) ~= "table" then
        addIssue(summary.errors, "invalid_bridge_file_list", "Bridge files must be listed in an array.", {
            resource = resourceName,
            side = side,
        })
        return
    end

    local seen = {}
    for index, file in ipairs(files) do
        if type(file) ~= "string" then
            addIssue(summary.errors, "invalid_bridge_file_entry", "Bridge file entries must be strings.", {
                resource = resourceName,
                side = side,
                index = index,
            })
        else
            local path = resolveResourcePath(resourceName, definition, file)
            if seen[path] then
                addIssue(summary.warnings, "duplicate_bridge_file", "Bridge file is listed more than once.", {
                    resource = resourceName,
                    side = side,
                    path = path,
                })
            end

            seen[path] = true
            summary.bridgeFiles = summary.bridgeFiles + 1
            validateFile(summary, path, {
                resource = resourceName,
                side = side,
                kind = "bridge",
                index = index,
            })
        end
    end
end

local function normalizeSqlEntry(entry)
    if type(entry) == "string" then
        return {
            path = entry,
        }
    end

    if type(entry) == "table" then
        return entry
    end

    return nil
end

local function validateRequiresTables(summary, entry, context)
    if entry.requiresTables == nil then
        return
    end

    if type(entry.requiresTables) ~= "table" then
        addIssue(summary.errors, "invalid_sql_requires_tables", "requiresTables must be an array of table names.", context)
        return
    end

    for index, tableName in ipairs(entry.requiresTables) do
        if type(tableName) ~= "string" or tableName == "" then
            addIssue(summary.errors, "invalid_sql_required_table", "requiresTables entries must be non-empty strings.", cloneContext(context, {
                index = index,
            }))
        end
    end
end

local function validateSqlEntries(summary, resourceName, definition, entries, scope)
    if entries == nil then
        return
    end

    if type(entries) ~= "table" then
        addIssue(summary.errors, "invalid_sql_file_list", "SQL files must be listed in an array.", {
            resource = resourceName,
            scope = scope,
        })
        return
    end

    local seen = {}
    for index, rawEntry in ipairs(entries) do
        local entry = normalizeSqlEntry(rawEntry)
        local context = {
            resource = resourceName,
            scope = scope,
            kind = "sql",
            index = index,
        }

        if not entry then
            addIssue(summary.errors, "invalid_sql_file_entry", "SQL file entries must be strings or tables.", context)
        elseif type(entry.path) ~= "string" or entry.path == "" then
            addIssue(summary.errors, "invalid_sql_file_path", "SQL file entry is missing a path.", context)
        else
            local path = resolveResourcePath(resourceName, definition, entry.path, entry.absolute == true)
            if seen[path] then
                addIssue(summary.warnings, "duplicate_sql_file", "SQL file is listed more than once in the same scope.", cloneContext(context, {
                    path = path,
                }))
            end

            seen[path] = true
            summary.sqlFiles = summary.sqlFiles + 1
            validateFile(summary, path, context)
            validateRequiresTables(summary, entry, context)
        end
    end
end

local function validateFrameworkSql(summary, resourceName, definition, frameworkFiles)
    if frameworkFiles == nil then
        return
    end

    if type(frameworkFiles) ~= "table" then
        addIssue(summary.errors, "invalid_framework_sql_files", "sql.frameworkFiles must be a table keyed by framework.", {
            resource = resourceName,
        })
        return
    end

    for framework, entries in pairs(frameworkFiles) do
        validateSqlEntries(summary, resourceName, definition, entries, "framework:" .. tostring(framework))
    end
end

function Core.registerResource(resourceName, definition)
    if type(resourceName) ~= "string" or resourceName == "" then
        return false, Core.fail("invalid_resource_registration", "Resource registration expects a non-empty resource name.")
    end

    if type(definition) ~= "table" then
        definition = {}
    end

    definition.name = definition.name or resourceName
    definition.path = definition.path or ("resources/" .. resourceName)
    definition.bridge = definition.bridge or {}
    definition.sql = definition.sql or {}

    Core.resources[resourceName] = definition
    Core.log("debug", "Resource registered.", {
        resource = resourceName,
        path = definition.path,
    })

    return true, definition
end

function Core.getResourceDefinition(resourceName)
    if type(resourceName) ~= "string" then
        return nil
    end

    return Core.resources and Core.resources[resourceName] or nil
end

function Core.listRegisteredResources()
    local names = {}

    for resourceName in pairs(Core.resources or {}) do
        names[#names + 1] = resourceName
    end

    table.sort(names)
    return names
end

function Core.validateResourceDefinitions()
    local summary = {
        ok = true,
        resources = 0,
        bridgeFiles = 0,
        sqlFiles = 0,
        warnings = {},
        errors = {},
    }

    for _, resourceName in ipairs(Core.listRegisteredResources()) do
        local definition = Core.resources[resourceName]
        summary.resources = summary.resources + 1

        if type(definition) ~= "table" then
            addIssue(summary.errors, "invalid_resource_definition", "Resource definition must be a table.", {
                resource = resourceName,
            })
        else
            local resourcePath = normalizePath(definition.path)
            if resourcePath == "" then
                addIssue(summary.errors, "invalid_resource_path", "Resource definition is missing a path.", {
                    resource = resourceName,
                })
            else
                validateFile(summary, resolveResourcePath(resourceName, definition, "resource.lua"), {
                    resource = resourceName,
                    kind = "resource",
                })
            end

            if type(definition.bridge) ~= "table" then
                addIssue(summary.errors, "invalid_bridge_definition", "Resource bridge definition must be a table.", {
                    resource = resourceName,
                })
            else
                if definition.bridge.locked ~= nil then
                    addIssue(summary.warnings, "deprecated_bridge_locked_flag", "bridge.locked is ignored by lyre_bridge.", {
                        resource = resourceName,
                    })
                end

                validateBridgeFiles(summary, resourceName, definition, "client", definition.bridge.client)
                validateBridgeFiles(summary, resourceName, definition, "server", definition.bridge.server)
            end

            if type(definition.sql) ~= "table" then
                addIssue(summary.errors, "invalid_sql_definition", "Resource SQL definition must be a table.", {
                    resource = resourceName,
                })
            else
                if definition.sql.locked ~= nil then
                    addIssue(summary.warnings, "deprecated_sql_locked_flag", "sql.locked is ignored by lyre_bridge.", {
                        resource = resourceName,
                    })
                end

                validateSqlEntries(summary, resourceName, definition, definition.sql.files, "common")
                validateFrameworkSql(summary, resourceName, definition, definition.sql.frameworkFiles)
            end
        end
    end

    summary.ok = #summary.errors == 0
    return summary
end
