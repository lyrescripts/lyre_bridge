CREATE TABLE IF NOT EXISTS `lyre_tennis_players` (
    `identifier` VARCHAR(255) PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `elo` INT NOT NULL DEFAULT 0,
    `elo_peak` INT NOT NULL DEFAULT 0,
    `matches_played` INT NOT NULL DEFAULT 0,
    `matches_won` INT NOT NULL DEFAULT 0,
    `matches_lost` INT NOT NULL DEFAULT 0,
    `points_won` INT NOT NULL DEFAULT 0,
    `games_won` INT NOT NULL DEFAULT 0,
    `games_lost` INT NOT NULL DEFAULT 0,
    `sets_won` INT NOT NULL DEFAULT 0,
    `sets_lost` INT NOT NULL DEFAULT 0,
    `aces` INT NOT NULL DEFAULT 0,
    `double_faults` INT NOT NULL DEFAULT 0,
    `winstreak` INT NOT NULL DEFAULT 0,
    `winstreak_max` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_elo` (`elo`),
    INDEX `idx_matches_played` (`matches_played`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `lyre_tennis_players_weekly` (
    `identifier` VARCHAR(255) PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `elo_gained` INT NOT NULL DEFAULT 0,
    `matches_played` INT NOT NULL DEFAULT 0,
    `matches_won` INT NOT NULL DEFAULT 0,
    `matches_lost` INT NOT NULL DEFAULT 0,
    `points_won` INT NOT NULL DEFAULT 0,
    `games_won` INT NOT NULL DEFAULT 0,
    `games_lost` INT NOT NULL DEFAULT 0,
    `sets_won` INT NOT NULL DEFAULT 0,
    `sets_lost` INT NOT NULL DEFAULT 0,
    `aces` INT NOT NULL DEFAULT 0,
    `double_faults` INT NOT NULL DEFAULT 0,
    `winstreak` INT NOT NULL DEFAULT 0,
    `winstreak_max` INT NOT NULL DEFAULT 0,
    INDEX `idx_elo_gained` (`elo_gained`),
    INDEX `idx_matches_won` (`matches_won`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `lyre_tennis_players_monthly` (
    `identifier` VARCHAR(255) PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `elo_gained` INT NOT NULL DEFAULT 0,
    `matches_played` INT NOT NULL DEFAULT 0,
    `matches_won` INT NOT NULL DEFAULT 0,
    `matches_lost` INT NOT NULL DEFAULT 0,
    `points_won` INT NOT NULL DEFAULT 0,
    `games_won` INT NOT NULL DEFAULT 0,
    `games_lost` INT NOT NULL DEFAULT 0,
    `sets_won` INT NOT NULL DEFAULT 0,
    `sets_lost` INT NOT NULL DEFAULT 0,
    `aces` INT NOT NULL DEFAULT 0,
    `double_faults` INT NOT NULL DEFAULT 0,
    `winstreak` INT NOT NULL DEFAULT 0,
    `winstreak_max` INT NOT NULL DEFAULT 0,
    INDEX `idx_elo_gained` (`elo_gained`),
    INDEX `idx_matches_won` (`matches_won`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `lyre_tennis_matches` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player1_identifier` VARCHAR(255) NOT NULL,
    `player2_identifier` VARCHAR(255) NOT NULL,
    `winner_identifier` VARCHAR(255) NOT NULL,
    `match_type` ENUM('ranked', 'friendly') NOT NULL,
    `match_format` ENUM('singles', 'doubles') NOT NULL DEFAULT 'singles',
    `final_score` VARCHAR(50) NOT NULL,
    `player1_elo_before` INT DEFAULT NULL,
    `player2_elo_before` INT DEFAULT NULL,
    `player1_elo_change` INT DEFAULT NULL,
    `player2_elo_change` INT DEFAULT NULL,
    `player1_points` INT NOT NULL DEFAULT 0,
    `player2_points` INT NOT NULL DEFAULT 0,
    `player1_games` INT NOT NULL DEFAULT 0,
    `player2_games` INT NOT NULL DEFAULT 0,
    `player1_sets` INT NOT NULL DEFAULT 0,
    `player2_sets` INT NOT NULL DEFAULT 0,
    `player1_aces` INT NOT NULL DEFAULT 0,
    `player2_aces` INT NOT NULL DEFAULT 0,
    `player1_double_faults` INT NOT NULL DEFAULT 0,
    `player2_double_faults` INT NOT NULL DEFAULT 0,
    `team1_player1_identifier` VARCHAR(255) DEFAULT NULL,
    `team1_player2_identifier` VARCHAR(255) DEFAULT NULL,
    `team2_player1_identifier` VARCHAR(255) DEFAULT NULL,
    `team2_player2_identifier` VARCHAR(255) DEFAULT NULL,
    `winner_team` TINYINT DEFAULT NULL,
    `court_id` VARCHAR(100) DEFAULT NULL,
    `duration_seconds` INT DEFAULT NULL,
    `played_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player1` (`player1_identifier`),
    INDEX `idx_player2` (`player2_identifier`),
    INDEX `idx_winner` (`winner_identifier`),
    INDEX `idx_match_type` (`match_type`),
    INDEX `idx_played_at` (`played_at`)
) ENGINE=InnoDB;

ALTER TABLE `lyre_tennis_matches` ADD COLUMN IF NOT EXISTS `match_format` ENUM('singles', 'doubles') NOT NULL DEFAULT 'singles' AFTER `match_type`;
ALTER TABLE `lyre_tennis_matches` ADD COLUMN IF NOT EXISTS `team1_player1_identifier` VARCHAR(255) DEFAULT NULL AFTER `player2_double_faults`;
ALTER TABLE `lyre_tennis_matches` ADD COLUMN IF NOT EXISTS `team1_player2_identifier` VARCHAR(255) DEFAULT NULL AFTER `team1_player1_identifier`;
ALTER TABLE `lyre_tennis_matches` ADD COLUMN IF NOT EXISTS `team2_player1_identifier` VARCHAR(255) DEFAULT NULL AFTER `team1_player2_identifier`;
ALTER TABLE `lyre_tennis_matches` ADD COLUMN IF NOT EXISTS `team2_player2_identifier` VARCHAR(255) DEFAULT NULL AFTER `team2_player1_identifier`;
ALTER TABLE `lyre_tennis_matches` ADD COLUMN IF NOT EXISTS `winner_team` TINYINT DEFAULT NULL AFTER `team2_player2_identifier`;

DROP EVENT IF EXISTS `lyre_tennis_weekly_reset`;
DROP EVENT IF EXISTS `lyre_tennis_monthly_reset`;

CREATE EVENT IF NOT EXISTS `lyre_tennis_weekly_reset`
ON SCHEDULE EVERY 1 WEEK
STARTS (SELECT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) DAY), '%Y-%m-%d 00:00:00'))
ON COMPLETION PRESERVE
ENABLE
DO
    TRUNCATE TABLE `lyre_tennis_players_weekly`;

CREATE EVENT IF NOT EXISTS `lyre_tennis_monthly_reset`
ON SCHEDULE EVERY 1 MONTH
STARTS (SELECT DATE_FORMAT(DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY), '%Y-%m-%d 00:00:00'))
ON COMPLETION PRESERVE
ENABLE
DO
    TRUNCATE TABLE `lyre_tennis_players_monthly`;
