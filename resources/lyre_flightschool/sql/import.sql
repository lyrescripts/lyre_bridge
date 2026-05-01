CREATE TABLE IF NOT EXISTS `lyre_flightschool` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `firstname` VARCHAR(50) DEFAULT NULL,
    `lastname` VARCHAR(50) DEFAULT NULL,
    `theory_passed` TINYINT(1) NOT NULL DEFAULT 0,
    `theory_score` INT(11) DEFAULT NULL,
    `theory_total` INT(11) DEFAULT NULL,
    `theory_passed_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @table_exists = (
    SELECT COUNT(*)
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
    AND table_name = 'licenses'
);

SET @insert_sql = IF(@table_exists > 0,
    "INSERT IGNORE INTO `licenses` (`type`, `label`) VALUES
        ('fly_plane', 'Pilot License'),
        ('fly_heli', 'Helicopter License')",
    "SELECT 1"
);

PREPARE stmt FROM @insert_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
