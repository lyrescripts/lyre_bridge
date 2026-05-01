CREATE TABLE `lyre_carwash-vehicles` (
    plate VARCHAR(99) PRIMARY KEY,
    dirtLevel INT,
    fixedUntil BIGINT
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lyre_carwash-stations` (
    `id` VARCHAR(99) PRIMARY KEY,
    `owner` LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    `sellState` BOOLEAN,
    `sellPrice` INT,
    `state` VARCHAR(99),
    `offers` LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    `account` INT,
    `stocks` LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    `conditions` LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    `upgrades` LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
