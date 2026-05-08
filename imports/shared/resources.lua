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

local function cloneTable(source)
    local cloned = {}

    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            cloned[key] = cloneTable(value)
        else
            cloned[key] = value
        end
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

local bridgeConventions = {
    { key = "ESX", file = "esx" },
    { key = "QBOX", file = "qbox" },
    { key = "QBCORE", file = "qbcore" },
    { key = "STANDALONE", file = "standalone" },
    { key = "EXAMPLE", file = "example" },
}

local defaultBridgeCandidateNames = { "ESX", "QBOX", "QBCORE", "STANDALONE", "EXAMPLE" }

local genericBridgeFiles = {
    client = {
        "bridge/client/client.lua",
        "bridge/client/main.lua",
    },
    server = {
        "bridge/server/server.lua",
        "bridge/server/main.lua",
    },
}

local commonSqlConventions = {
    { id = "import_sql", path = "sql/import.sql", required = true, order = 10 },
}

local frameworkSqlConventions = {
    ESX = {
        { id = "import_esx", path = "sql/import_esx.sql", required = true, order = 10 },
        { id = "inventory_items_esx", path = "sql/inventory_items/esx.sql", required = false, order = 100, requiresTables = { "items" } },
    },
    QBCORE = {
        { id = "import_qbcore", path = "sql/import_qbcore.sql", required = true, order = 10 },
        { id = "import_qb", path = "sql/import_qb.sql", required = true, order = 10, fallbackFor = "sql/import_qbcore.sql" },
        { id = "inventory_items_qbcore", path = "sql/inventory_items/qbcore.sql", required = false, order = 100, requiresTables = { "items" } },
        { id = "inventory_items_qb", path = "sql/inventory_items/qb.sql", required = false, order = 100, requiresTables = { "items" }, fallbackFor = "sql/inventory_items/qbcore.sql" },
    },
    QBOX = {
        { id = "import_qbox", path = "sql/import_qbox.sql", required = true, order = 10 },
        { id = "import_qb", path = "sql/import_qb.sql", required = true, order = 10, fallbackFor = "sql/import_qbox.sql" },
        { id = "inventory_items_qbox", path = "sql/inventory_items/qbox.sql", required = false, order = 100, requiresTables = { "items" } },
        { id = "inventory_items_qb", path = "sql/inventory_items/qb.sql", required = false, order = 100, requiresTables = { "items" }, fallbackFor = "sql/inventory_items/qbox.sql" },
    },
}

Core.resourceConventions = Core.resourceConventions or {
    bridge = bridgeConventions,
    sql = {
        common = commonSqlConventions,
        framework = frameworkSqlConventions,
    },
}

local function getBridgeConventions()
    local conventions = Core.resourceConventions and Core.resourceConventions.bridge
    return type(conventions) == "table" and conventions or bridgeConventions
end

local function getCommonSqlConventions()
    local conventions = Core.resourceConventions and Core.resourceConventions.sql and Core.resourceConventions.sql.common

    return type(conventions) == "table" and conventions or commonSqlConventions
end

local function getFrameworkSqlConventions()
    local conventions = Core.resourceConventions and Core.resourceConventions.sql and Core.resourceConventions.sql.framework

    return type(conventions) == "table" and conventions or frameworkSqlConventions
end

local function canProbeResourceFiles()
    return type(LoadResourceFile) == "function"
end

local function detectedResourceFileExists(path)
    return canProbeResourceFiles() and resourceFileExists(path)
end

local function addUniquePath(target, path)
    path = normalizePath(path)

    if path == "" then
        return false
    end

    for _, existing in ipairs(target) do
        if normalizePath(existing) == path then
            return false
        end
    end

    target[#target + 1] = path
    return true
end

local function addUniqueSqlEntry(target, entry)
    if type(entry) ~= "table" or type(entry.path) ~= "string" or entry.path == "" then
        return false
    end

    local path = normalizePath(entry.path)
    for _, existing in ipairs(target) do
        if type(existing) == "table" and normalizePath(existing.path) == path then
            return false
        end
    end

    local cloned = cloneTable(entry)
    cloned.path = path
    cloned.fallbackFor = nil
    target[#target + 1] = cloned
    return true
end

local function detectRelativeFile(resourceName, definition, relativePath)
    local fullPath = resolveResourcePath(resourceName, definition, relativePath)
    return detectedResourceFileExists(fullPath)
end

local function bridgeCandidatesFor(side, bridgeName)
    local prefix = side == "server" and "sv" or "cl"
    return {
        ("bridge/%s/%s_%s.lua"):format(side, prefix, bridgeName),
        ("bridge/%s/%s.lua"):format(side, bridgeName),
    }
end

local function discoverBridgeFiles(resourceName, definition, side)
    local files = {}

    for _, convention in ipairs(getBridgeConventions()) do
        for _, candidate in ipairs(bridgeCandidatesFor(side, convention.file)) do
            if detectRelativeFile(resourceName, definition, candidate) then
                addUniquePath(files, candidate)
                break
            end
        end
    end

    for _, candidate in ipairs(genericBridgeFiles[side] or {}) do
        if detectRelativeFile(resourceName, definition, candidate) then
            addUniquePath(files, candidate)
        end
    end

    return files
end

local function discoverSqlEntries(resourceName, definition)
    local sql = {
        files = {},
        frameworkFiles = {},
    }

    for _, entry in ipairs(getCommonSqlConventions()) do
        if detectRelativeFile(resourceName, definition, entry.path) then
            addUniqueSqlEntry(sql.files, entry)
        end
    end

    for framework, entries in pairs(getFrameworkSqlConventions()) do
        for _, entry in ipairs(entries) do
            local fallbackForExists = type(entry.fallbackFor) == "string"
                and detectRelativeFile(resourceName, definition, entry.fallbackFor)

            if not fallbackForExists and detectRelativeFile(resourceName, definition, entry.path) then
                sql.frameworkFiles[framework] = sql.frameworkFiles[framework] or {}
                addUniqueSqlEntry(sql.frameworkFiles[framework], entry)
            end
        end
    end

    return sql
end

local function applyDiscoveredBridge(resourceName, definition)
    local bridge = type(definition.bridge) == "table" and definition.bridge or {}
    local discoveryDisabled = definition.bridge == false or bridge.autoDiscover == false

    if discoveryDisabled then
        definition.bridge = {
            client = bridge.client or {},
            server = bridge.server or {},
            autoDiscover = false,
            required = bridge.required,
        }
        return
    end

    if bridge.client == nil then
        bridge.client = discoverBridgeFiles(resourceName, definition, "client")
    end

    if bridge.server == nil then
        bridge.server = discoverBridgeFiles(resourceName, definition, "server")
    end

    definition.bridge = bridge
end

local function applyDiscoveredSql(resourceName, definition)
    local sql = type(definition.sql) == "table" and definition.sql or {}
    local discoveryDisabled = definition.sql == false or sql.autoDiscover == false

    if discoveryDisabled then
        definition.sql = {
            files = sql.files or {},
            frameworkFiles = sql.frameworkFiles or {},
            autoDiscover = false,
            required = sql.required,
        }
        return
    end

    local discovered = discoverSqlEntries(resourceName, definition)

    if sql.files == nil then
        sql.files = discovered.files
    end

    if sql.frameworkFiles == nil then
        sql.frameworkFiles = discovered.frameworkFiles
    end

    definition.sql = sql
end

local function countArray(value)
    return type(value) == "table" and #value or 0
end

local function bridgeSideRequired(definition, side)
    local bridge = definition and definition.bridge
    local required = type(bridge) == "table" and bridge.required

    if required == true then
        return true
    end

    if type(required) == "table" then
        return required[side] == true
    end

    return false
end

local function sqlEntryCount(sql)
    if type(sql) ~= "table" then
        return 0
    end

    local count = countArray(sql.files)
    if type(sql.frameworkFiles) == "table" then
        for _, entries in pairs(sql.frameworkFiles) do
            count = count + countArray(entries)
        end
    end

    return count
end

local function sortedFrameworkSqlSummary(frameworkFiles)
    local frameworks = {}

    for framework, entries in pairs(frameworkFiles or {}) do
        if type(entries) == "table" and #entries > 0 then
            frameworks[#frameworks + 1] = {
                framework = framework,
                files = #entries,
            }
        end
    end

    table.sort(frameworks, function(left, right)
        return tostring(left.framework) < tostring(right.framework)
    end)

    return frameworks
end

local function buildResourceIdentity(resourceName, definition)
    return {
        resource = resourceName,
        name = definition.name,
        path = definition.path,
        bridge = {
            clientFiles = countArray(definition.bridge and definition.bridge.client),
            serverFiles = countArray(definition.bridge and definition.bridge.server),
            client = cloneTable(definition.bridge and definition.bridge.client or {}),
            server = cloneTable(definition.bridge and definition.bridge.server or {}),
            required = (
                type(definition.bridge and definition.bridge.required) == "table"
                and cloneTable(definition.bridge.required)
                or (definition.bridge and definition.bridge.required == true or false)
            ),
            defaultCandidates = cloneTable(defaultBridgeCandidateNames),
        },
        sql = {
            commonFiles = countArray(definition.sql and definition.sql.files),
            files = cloneTable(definition.sql and definition.sql.files or {}),
            frameworkFiles = sortedFrameworkSqlSummary(definition.sql and definition.sql.frameworkFiles),
            frameworks = cloneTable(definition.sql and definition.sql.frameworkFiles or {}),
            required = definition.sql and definition.sql.required == true or false,
        },
        metadata = definition.metadata or {},
    }
end

local function normalizeResourceDefinition(resourceName, definition)
    if type(definition) ~= "table" then
        definition = {}
    end

    definition.name = definition.name or resourceName
    definition.path = normalizePath(definition.path or ("resources/" .. resourceName))
    definition.metadata = definition.metadata or {}
    definition.metadata.resource = definition.metadata.resource or resourceName
    definition.metadata.path = definition.metadata.path or definition.path

    applyDiscoveredBridge(resourceName, definition)
    applyDiscoveredSql(resourceName, definition)

    definition.identity = buildResourceIdentity(resourceName, definition)
    return definition
end

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
        local isResourceIdentity = context and context.kind == "resource"
        local code = isResourceIdentity and "resource_identity_missing" or "runtime_file_missing"
        local message = "Runtime file is missing in lyre_bridge."

        if isResourceIdentity then
            message = "Resource identity file is missing. Add `lyre_bridge/resources/<resource>/resource.lua` with `LyreBridge.registerResource(\"<resource>\")`."
        end

        return false, Core.fail(code, message, cloneContext(context, {
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
        if bridgeSideRequired(definition, side) then
            return false, Core.fail("resource_bridge_missing", "Resource requires bridge files for this side, but none were discovered or declared.", {
                resource = resourceName,
                side = side,
            })
        end

        return true, definition
    end

    if type(files) ~= "table" then
        return false, Core.fail("invalid_bridge_file_list", "Bridge files must be listed in an array.", {
            resource = resourceName,
            side = side,
        })
    end

    if #files == 0 and bridgeSideRequired(definition, side) then
        return false, Core.fail("resource_bridge_missing", "Resource requires bridge files for this side, but the file list is empty.", {
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

    if not resourceName:match("^[%w_%-]+$") then
        return false, Core.fail("invalid_resource_name", "Resource names may only contain letters, numbers, underscores and dashes.", {
            resource = resourceName,
        })
    end

    definition = normalizeResourceDefinition(resourceName, definition)

    Core.resources[resourceName] = definition
    Core.log("debug", "Resource registered.", {
        resource = resourceName,
        path = definition.path,
        clientBridgeFiles = definition.identity.bridge.clientFiles,
        serverBridgeFiles = definition.identity.bridge.serverFiles,
        sqlFiles = definition.identity.sql.commonFiles,
    })

    return true, definition
end

function Core.getResourceDefinition(resourceName)
    if type(resourceName) ~= "string" then
        return nil
    end

    return Core.resources and Core.resources[resourceName] or nil
end

function Core.getResourceIdentity(resourceName)
    if type(resourceName) ~= "string" or resourceName == "" then
        return nil
    end

    if not Core.resources or not Core.resources[resourceName] then
        Core.loadResourceDefinition(resourceName)
    end

    local definition = Core.resources and Core.resources[resourceName]
    return definition and definition.identity or nil
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
                local expectedPath = "resources/" .. resourceName
                if resourcePath ~= expectedPath then
                    addIssue(summary.warnings, "non_standard_resource_path", "Resource path differs from the convention. Prefer resources/<resource> unless this is intentional.", {
                        resource = resourceName,
                        path = resourcePath,
                        expected = expectedPath,
                    })
                end

                validateFile(summary, resolveResourcePath(resourceName, definition, "resource.lua"), {
                    resource = resourceName,
                    kind = "resource",
                })
            end

            if type(definition.identity) ~= "table" then
                addIssue(summary.errors, "missing_resource_identity", "Resource identity was not generated. Use LyreBridge.registerResource(resourceName).", {
                    resource = resourceName,
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

                for _, side in ipairs({ "client", "server" }) do
                    if bridgeSideRequired(definition, side) and countArray(definition.bridge[side]) == 0 then
                        addIssue(summary.errors, "resource_bridge_missing", "Resource requires bridge files for this side, but none were discovered or declared.", {
                            resource = resourceName,
                            side = side,
                        })
                    end
                end
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

                if definition.sql.required == true and sqlEntryCount(definition.sql) == 0 then
                    addIssue(summary.errors, "resource_sql_missing", "Resource requires SQL, but no SQL files were discovered or declared.", {
                        resource = resourceName,
                    })
                end
            end
        end
    end

    summary.ok = #summary.errors == 0
    return summary
end
