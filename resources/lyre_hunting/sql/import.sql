CREATE TABLE IF NOT EXISTS `lyre_hunting_players` (
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `xp` INT DEFAULT 0,
    `level` INT DEFAULT 1,
    `has_license` TINYINT(1) DEFAULT 0,
    `daily_streak` INT DEFAULT 0,
    `last_daily_date` DATE DEFAULT NULL,
    `total_earnings` INT DEFAULT 0,
    `tournament_wins` INT DEFAULT 0,
    `points` INT DEFAULT 0,
    `animals_killed` INT DEFAULT 0,
    `animals_killed_by_type` LONGTEXT DEFAULT NULL,
    `missions_completed` INT DEFAULT 0,
    `daily_missions_completed` INT DEFAULT 0,
    `traps_placed` INT DEFAULT 0,
    `traps_caught` INT DEFAULT 0,
    `items_sold` INT DEFAULT 0,
    `illegal_items_sold` INT DEFAULT 0,
    `meat_cooked` INT DEFAULT 0,
    `completed_tutorials` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    INDEX `idx_points` (`points` DESC),
    INDEX `idx_xp` (`xp` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lyre_hunting_players_weekly` (
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `points_gained` INT DEFAULT 0,
    `xp_gained` INT DEFAULT 0,
    `animals_killed` INT DEFAULT 0,
    `missions_completed` INT DEFAULT 0,
    `earnings` INT DEFAULT 0,
    PRIMARY KEY (`identifier`),
    INDEX `idx_points` (`points_gained` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lyre_hunting_players_monthly` (
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `points_gained` INT DEFAULT 0,
    `xp_gained` INT DEFAULT 0,
    `animals_killed` INT DEFAULT 0,
    `missions_completed` INT DEFAULT 0,
    `earnings` INT DEFAULT 0,
    PRIMARY KEY (`identifier`),
    INDEX `idx_points` (`points_gained` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lyre_hunting_traps` (
    `id` INT AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `trap_type` VARCHAR(50) NOT NULL,
    `zone_id` VARCHAR(50) NOT NULL,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `heading` FLOAT DEFAULT 0.0,
    `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_checked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `caught_animal` VARCHAR(50) DEFAULT NULL,
    `caught_quality` VARCHAR(20) DEFAULT NULL,
    `caught_at` TIMESTAMP DEFAULT NULL,
    `is_spoiled` TINYINT(1) DEFAULT 0,
    PRIMARY KEY (`id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_zone` (`zone_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lyre_hunting_missions` (
    `id` INT AUTO_INCREMENT,
    `mission_type` VARCHAR(50) NOT NULL,
    `target_animal` VARCHAR(50) DEFAULT NULL,
    `target_item` VARCHAR(80) DEFAULT NULL,
    `target_quality` VARCHAR(20) DEFAULT NULL,
    `target_quantity` INT DEFAULT 1,
    `reward_money` INT NOT NULL,
    `reward_xp` INT NOT NULL,
    `status` ENUM('available','accepted','completed','expired','abandoned') NOT NULL DEFAULT 'available',
    `accepted_by` VARCHAR(60) DEFAULT NULL,
    `accepted_at` TIMESTAMP NULL DEFAULT NULL,
    `deadline_at` TIMESTAMP NULL DEFAULT NULL,
    `current_progress` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_accepted_by` (`accepted_by`),
    INDEX `idx_deadline` (`status`, `deadline_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lyre_hunting_daily_missions` (
    `id` INT AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `mission_type` VARCHAR(50) NOT NULL,
    `target_animal` VARCHAR(50) DEFAULT NULL,
    `target_quantity` INT DEFAULT 1,
    `current_progress` INT DEFAULT 0,
    `reward_money` INT NOT NULL,
    `reward_xp` INT NOT NULL,
    `is_completed` TINYINT(1) DEFAULT 0,
    `assigned_date` DATE NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_player_date` (`identifier`, `assigned_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lyre_hunting_tournaments` (
    `id` INT AUTO_INCREMENT,
    `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `ends_at` TIMESTAMP NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `participants` LONGTEXT DEFAULT NULL,
    `winner_identifier` VARCHAR(60) DEFAULT NULL,
    `winner_name` VARCHAR(100) DEFAULT NULL,
    `winner_prize` INT DEFAULT 0,
    PRIMARY KEY (`id`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP EVENT IF EXISTS `lyre_hunting_weekly_reset`;
DROP EVENT IF EXISTS `lyre_hunting_monthly_reset`;

CREATE EVENT IF NOT EXISTS `lyre_hunting_weekly_reset`
ON SCHEDULE EVERY 1 WEEK
STARTS (SELECT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) DAY), '%Y-%m-%d 00:00:00'))
ON COMPLETION PRESERVE
ENABLE
DO
    TRUNCATE TABLE `lyre_hunting_players_weekly`;

CREATE EVENT IF NOT EXISTS `lyre_hunting_monthly_reset`
ON SCHEDULE EVERY 1 MONTH
STARTS (SELECT DATE_FORMAT(DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY), '%Y-%m-%d 00:00:00'))
ON COMPLETION PRESERVE
ENABLE
DO
    TRUNCATE TABLE `lyre_hunting_players_monthly`;
