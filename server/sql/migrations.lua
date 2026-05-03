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
