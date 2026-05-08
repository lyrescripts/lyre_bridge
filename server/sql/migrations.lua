local SQL = LyreBridge.SQL
local Private = SQL._private
local Migrations = Private.migrations or {}

Private.migrations = Migrations

function Migrations.ensureTable()
    local query = ([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` VARCHAR(190) NOT NULL,
            `resource` VARCHAR(100) NOT NULL,
            `checksum` VARCHAR(64) NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'applied',
            `error` LONGTEXT DEFAULT NULL,
            `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_resource` (`resource`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]]):format(SQL.config.migrationTable)

    return Private.queryAwait("query", query, {}, { operation = "ensure_migration_table" })
end

function Migrations.exists(migrationId)
    local ok, response = Private.queryAwait("single", ("SELECT `id`, `checksum`, `status` FROM `%s` WHERE `id` = ? LIMIT 1"):format(SQL.config.migrationTable), {
        migrationId,
    }, { operation = "migration_exists", migration = migrationId })

    if not ok then
        return false, response
    end

    return response ~= nil, response
end

function Migrations.mark(migrationId, resourceName, hash, status, errorText)
    local query = ([[
        INSERT INTO `%s` (`id`, `resource`, `checksum`, `status`, `error`)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `checksum` = VALUES(`checksum`),
            `status` = VALUES(`status`),
            `error` = VALUES(`error`),
            `applied_at` = CURRENT_TIMESTAMP
    ]]):format(SQL.config.migrationTable)

    return Private.queryAwait("update", query, {
        migrationId,
        resourceName,
        hash,
        status,
        errorText,
    }, { operation = "mark_migration", migration = migrationId })
end

function Migrations.list(resourceName)
    local query = ([[
        SELECT `id`, `resource`, `checksum`, `status`, `error`, `applied_at`
        FROM `%s`
        WHERE `resource` = ?
        ORDER BY `applied_at` DESC, `id` ASC
    ]]):format(SQL.config.migrationTable)

    return Private.queryAwait("query", query, {
        resourceName,
    }, { operation = "list_migrations", resource = resourceName })
end

function SQL.getResourceMigrations(resourceName)
    resourceName = resourceName or (type(GetCurrentResourceName) == "function" and GetCurrentResourceName() or "unknown")

    local context = {
        resource = resourceName,
        operation = "list_migrations",
    }

    if not SQL.ready() then
        return Core.fail("mysql_not_ready", "oxmysql is not ready; cannot read SQL migrations.", context)
    end

    local ok, migrationTableError = Migrations.ensureTable()
    if not ok then
        return migrationTableError
    end

    local listed, rows = Migrations.list(resourceName)
    if not listed then
        return rows
    end

    return Private.result(true, rows or {}, nil, nil, context)
end
