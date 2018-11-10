CREATE TABLE `character_inventory` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`identifier` VARCHAR(255) NOT NULL,
	`item` VARCHAR(255) NOT NULL,
	`count` INT(11) NOT NULL,
	`skin_id` INT(11) NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `skin_id` (`skin_id`)
);

ALTER TABLE `users` ADD COLUMN `active_char_id` INT(11) NULL DEFAULT NULL;
ALTER TABLE `users` ADD INDEX `active_char_id` (`active_char_id`);