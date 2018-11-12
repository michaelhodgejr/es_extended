CREATE TABLE `character_inventory` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`identifier` VARCHAR(255) NOT NULL,
	`item` VARCHAR(255) NOT NULL,
	`count` INT(11) NOT NULL,
	`skin_id` INT(11) NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `skin_id` (`skin_id`)
);

ALTER TABLE `users` ADD COLUMN `active_char_id` TEXT NULL DEFAULT NULL;
ALTER TABLE `users` ADD INDEX `active_char_id` (`active_char_id`);
ALTER TABLE `skins` ADD COLUMN `loadout` TEXT NULL AFTER `identifier`;
ALTER TABLE `skins` ADD COLUMN `job` VARCHAR(250) NULL AFTER `identifier`;
ALTER TABLE `skins` ADD COLUMN `job_grade` int NULL AFTER `identifier`;

UPDATE users SET active_char_id = (SELECT id FROM skins WHERE active = 1 AND identifier = users.identifier);
UPDATE skins SET loadout = '[]', job_grade = 0, job = 'unemployed';


