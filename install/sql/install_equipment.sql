CREATE TABLE `%TABLE_PREFIX%equipment` (
  `equipment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category_id` int(10) unsigned NOT NULL DEFAULT '0',
  `status_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ispublished` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `description` text,
  `serialnumber` tinytext,
  `notes` text,
  `created` date NOT NULL,
  `updated` date NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`equipment_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `%TABLE_PREFIX%equipment_category` (
  `category_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ispublic` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `name` varchar(125) DEFAULT NULL,
  `description` text NOT NULL,
  `notes` tinytext NOT NULL,
  `created` date NOT NULL,
  `updated` date NOT NULL,
  PRIMARY KEY (`category_id`),
  KEY `ispublic` (`ispublic`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `%TABLE_PREFIX%equipment_status` (
  `status_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(125) DEFAULT NULL,
  `description` text NOT NULL,
  `image` text,
  `color` varchar(45) DEFAULT NULL,
  `baseline` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`status_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

CREATE TABLE `%TABLE_PREFIX%equipment_ticket` (
  `equipment_id` int(11) NOT NULL,
  `ticket_id` int(11) NOT NULL,
  `created` date NOT NULL,
  PRIMARY KEY (`equipment_id`,`ticket_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `%TABLE_PREFIX%list` (`name`, `created`,`notes`,`updated`)
VALUES ('equipment_status',NOW(),'internal equipment plugin list, do not modify',NOW()); 

INSERT INTO `%TABLE_PREFIX%list` (`name`, `created`,`notes`,`updated`)
VALUES ('equipment',NOW(),'internal equipment plugin list, do not modify',NOW()); 

INSERT INTO `%TABLE_PREFIX%form` (`type`, `deletable`,`title`, `notes`, `created`, `updated`)
VALUES ('G',0,'Equipment','Equipment internal form',NOW(),NOW()); 

DELIMITER $$
CREATE PROCEDURE `%TABLE_PREFIX%CreateEquipmentFormFields`()
BEGIN
	SET @form_id = (SELECT id FROM `%TABLE_PREFIX%form` WHERE title='Equipment');
	SET @status_list_id = (SELECT id FROM `%TABLE_PREFIX%list` WHERE `name`='equipment_status');
	SET @equipment_list_id = (SELECT id FROM `%TABLE_PREFIX%list` WHERE `name`='equipment');

	IF (@form_id IS NOT NULL) AND (@status_list_id IS NOT NULL) AND (@equipment_list_id IS NOT NULL) then
		INSERT INTO `%TABLE_PREFIX%form_field`
			(`form_id`,
			`type`,
			`label`,
			`required`,
			`private`,
			`edit_mask`,
			`name`,
			`sort`,
			`created`,
			`updated`)
			VALUES
			(@form_id,
			CONCAT('list-',@equipment_list_id),
			'Equipment',
			0,0,0,
			'equipment',			
			1,			
			NOW(),
			NOW());	

		INSERT INTO `%TABLE_PREFIX%form_fieldform_field`
			(`form_id`,
			`type`,
			`label`,
			`required`,
			`private`,
			`edit_mask`,
			`name`,
			`sort`,
			`created`,
			`updated`)
			VALUES
			(@form_id,
			CONCAT('list-',@status_list_id),
			'Status',
			0,0,0,
			'status',			
			2,			
			NOW(),
			NOW());					
	END IF;
END$$
DELIMITER ;

call `%TABLE_PREFIX%CreateEquipmentFormFields`;

DELIMITER $$

DROP TRIGGER IF EXISTS `%TABLE_PREFIX%equipment_ADEL`$$

CREATE TRIGGER `%TABLE_PREFIX%equipment_ADEL` AFTER DELETE ON `%TABLE_PREFIX%equipment` FOR EACH ROW
BEGIN
	SET @pk=OLD.equipment_id;
	SET @list_pk=(SELECT id FROM `%TABLE_PREFIX%list` WHERE name='equipment');
	DELETE FROM `%TABLE_PREFIX%list_items` WHERE list_id = @list_pk AND properties=CONCAT('',@pk); 
END$$
DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS `%TABLE_PREFIX%equipment_AINS`$$

CREATE TRIGGER `%TABLE_PREFIX%equipment_AINS` AFTER INSERT ON `%TABLE_PREFIX%equipment` FOR EACH ROW
BEGIN
	SET @pk=NEW.equipment_id;
	SET @list_pk=(SELECT id FROM `%TABLE_PREFIX%list` WHERE name='equipment');
	INSERT INTO `%TABLE_PREFIX%list_items` (list_id, `value`, `properties`)
	VALUES (@list_pk, NEW.name, CONCAT('',@pk)); 
END$$
DELIMITER ;


DELIMITER $$

DROP TRIGGER IF EXISTS `%TABLE_PREFIX%equipment_AUPD`$$

CREATE TRIGGER `%TABLE_PREFIX%equipment_AUPD` AFTER UPDATE ON `%TABLE_PREFIX%equipment` FOR EACH ROW
BEGIN
	SET @pk=NEW.equipment_id;
	SET @list_pk=(SELECT id FROM `%TABLE_PREFIX%list` WHERE name='equipment');

	IF NEW.is_active = 0 THEN
		DELETE FROM `%TABLE_PREFIX%list_items` WHERE list_id = @list_pk AND properties=CONCAT('',@pk);
	ELSE
		SET @list_item_pkid = (SELECT id 
							   FROM `%TABLE_PREFIX%items `
							   WHERE list_id = @list_pk AND properties=CONCAT('',@pk));

		IF (@list_item_pkid IS NOT NULL) AND (@list_item_pkid>0) THEN
			UPDATE `%TABLE_PREFIX%items` SET `value`= NEW.name 
			WHERE `properties`= CONCAT('',@pk) AND list_id=@list_pk;
		ELSE
			INSERT INTO `%TABLE_PREFIX%items` (list_id, `value`, `properties`)
			VALUES (@list_pk, NEW.name, CONCAT('',@pk));			
		END IF;
	END IF; 
END$$
DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS `%TABLE_PREFIX%equipment_status_AINS`$$

CREATE TRIGGER `%TABLE_PREFIX%equipment_status_AINS` AFTER INSERT ON `%TABLE_PREFIX%equipment_status` FOR EACH ROW
BEGIN
	SET @pk=NEW.status_id;
	SET @list_pk=(SELECT id FROM `%TABLE_PREFIX%list` WHERE name='equipment_status');
	INSERT INTO `%TABLE_PREFIX%list_items` (list_id, `value`, `properties`) 
	VALUES (@list_pk, NEW.name, CONCAT('',@pk));
END $$
DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS `%TABLE_PREFIX%equipment_status_AUPD`$$

CREATE TRIGGER `%TABLE_PREFIX%equipment_status_AUPD` AFTER UPDATE ON `%TABLE_PREFIX%equipment_status` FOR EACH ROW
BEGIN
	SET @pk=NEW.status_id;
	SET @list_pk=(SELECT id FROM `%TABLE_PREFIX%list` WHERE name='equipment_status'); 
	UPDATE `%TABLE_PREFIX%list_items` SET `value`= NEW.name WHERE `properties`= CONCAT('',@pk) AND list_id=@list_pk;
END $$
DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS `%TABLE_PREFIX%equipment_status_ADEL`$$

CREATE TRIGGER `%TABLE_PREFIX%equipment_status_ADEL` AFTER DELETE ON `%TABLE_PREFIX%equipment_status` FOR EACH ROW
BEGIN
	SET @pk=OLD.status_id; 
	SET @list_pk=(SELECT id FROM `%TABLE_PREFIX%list` WHERE name='equipment_status');
	DELETE FROM `%TABLE_PREFIX%list_items` WHERE list_id = @list_pk AND properties=CONCAT('',@pk);
END $$
DELIMITER ;


CREATE VIEW `%TABLE_PREFIX%EquipmentFormView` AS 
select `%TABLE_PREFIX%form`.`title` AS `title`,
`%TABLE_PREFIX%form_entry`.`id` AS `entry_id`,
`%TABLE_PREFIX%form_entry`.`object_id` AS `ticket_id`,
`%TABLE_PREFIX%form_field`.`id` AS `field_id`,
`%TABLE_PREFIX%form_field`.`label` AS `field_label`,
`%TABLE_PREFIX%form_entry_values`.`value` AS `value`,
`%TABLE_PREFIX%equipment`.`equipment_id` AS `equipment_id`,
`%TABLE_PREFIX%equipment_status`.`status_id` AS `status_id` 
from ((((`%TABLE_PREFIX%form_field` 
left join 
(`%TABLE_PREFIX%form_entry_values` join `%TABLE_PREFIX%form_entry`) 
on(((`%TABLE_PREFIX%form_field`.`id` = `%TABLE_PREFIX%form_entry_values`.`field_id`) and 
(`%TABLE_PREFIX%form_entry`.`id` = `%TABLE_PREFIX%form_entry_values`.`entry_id`)))) 
left join `%TABLE_PREFIX%form` 
on((`%TABLE_PREFIX%form`.`id` = `%TABLE_PREFIX%form_field`.`form_id`))) 
left join `%TABLE_PREFIX%equipment` 
on((`%TABLE_PREFIX%form_entry_values`.`value` = `%TABLE_PREFIX%equipment`.`name`))) 
left join `%TABLE_PREFIX%equipment_status` 
on((`%TABLE_PREFIX%form_entry_values`.`value` = `%TABLE_PREFIX%equipment_status`.`name`))) 
where ((`%TABLE_PREFIX%form`.`title` = 'Equipment') and 
(`%TABLE_PREFIX%form`.`id` = `%TABLE_PREFIX%form_entry`.`form_id`) and 
(`%TABLE_PREFIX%form_entry`.`object_type` = 'T'));

DELIMITER $$

DROP TRIGGER IF EXISTS `%TABLE_PREFIX%ticket_event_AINS`$$

CREATE TRIGGER `%TABLE_PREFIX%ticket_event_AINS` AFTER INSERT ON `%TABLE_PREFIX%ticket_event` FOR EACH ROW
BEGIN
	IF NEW.state='closed' THEN
		SET @equipment_id = (SELECT equipment_id FROM `%TABLE_PREFIX%equipment_ticket `
							WHERE ticket_id=NEW.ticket_id LIMIT 1);
		IF ((@equipment_id IS NOT NULL) AND (@equipment_id>0)) THEN
			SET @status_id = (SELECT status_id FROM `%TABLE_PREFIX%equipment_status`
							WHERE baseline=1 LIMIT 1);

			IF ((@status_id IS NOT NULL) AND (@status_id>0)) THEN
				UPDATE `%TABLE_PREFIX%equipment` SET status_id = @status_id
				WHERE equipment_id = @equipment_id; 
			END IF;
		END IF;

	ELSEIF NEW.state='created' THEN
		
		SET @status_id = (SELECT status_id FROM `%TABLE_PREFIX%EquipmentFormView` WHERE 
						ticket_id= NEW.ticket_id AND field_label='Status' LIMIT 1);
		SET @equipment_id = (SELECT equipment_id FROM `%TABLE_PREFIX%EquipmentFormView` WHERE 
							ticket_id= NEW.ticket_id AND field_label='Equipment' LIMIT 1);

		IF ((@status_id IS NOT NULL) AND 
			(@status_id >0)) AND 
			((@equipment_id IS NOT NULL) AND 
			(@equipment_id >0)) THEN						
				
				UPDATE `%TABLE_PREFIX%equipment` SET status_id = @status_id WHERE equipment_id=@equipment_id;
				INSERT INTO `%TABLE_PREFIX%equipment_ticket` (equipment_id, ticket_id, created) 
				VALUES (@equipment_id, NEW.ticket_id, NOW());
		END IF;
	
	END IF;
END$$
DELIMITER ;