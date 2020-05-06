SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

/* Create database containing triaxial test measurements, rock data and experiments metadata */
CREATE DATABASE IF NOT EXISTS `data_raw` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `data_raw`;

DELIMITER $$
DROP PROCEDURE IF EXISTS `Fetch_Specimen_Data`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Fetch_Specimen_Data` (IN `spec_no` INT)  NO SQL
BEGIN
#Using INNER JOIN to join the synchronous data, as we do not want to have
#any datasets with missing information
	DROP TABLE IF EXISTS `data_raw`.`joinSpecimenData`;
	CREATE TABLE `data_raw`.`joinSpecimenData` AS
		SELECT 
			`specimen_param`.`id` AS `specimen_id`,
			`specimen_param`.`name` AS `specimen_name`,
            `specimen_param`.`height`,
            `specimen_param`.`diameter`,
            `specimen_param`.`mass_sat`,
            `specimen_param`.`mass_wet`,
            `specimen_param`.`mass_dry`,
			`rock_data`.`name` AS `rock_name`,
			`rock_data`.`description`,
			`rock_data`.`density_wet`,
			`rock_data`.`density_sat`,
			`rock_data`.`density_dry`,
            `rock_data`.`density_grain`,
			`rock_data`.`perm_coeff`,
            `rock_data`.`porosity`,
            `rock_data`.`void_ratio`,
            `rock_data`.`uniAx_comp_strength`,
            `rock_data`.`uniAx_emodulus` 
		FROM 
			#Source table
			`data_raw`.`specimen_param` 
		#First join table    
		INNER JOIN 
			`data_raw`.`rock_data` ON  (
			`specimen_param`.`rock_id` = `rock_data`.`id`
			)
		#Which specimen should be joined?
		WHERE
			`specimen_param`.`id` = spec_no;
END$$

DELIMITER ;

/* Table containing meta data for each experiment. The 'experiment_no' is the primary key
	and the main conntection between all datasets.  */
DROP TABLE IF EXISTS `experiments`;
CREATE TABLE `experiments` (
  `experiment_no` smallint(5) UNSIGNED NOT NULL,
  `specimen_id` smallint(5) NOT NULL,
  `description` varchar(2500) NOT NULL,
  `comment` varchar(2500) NOT NULL,
  `time_start` datetime NOT NULL,
  `time_end` datetime NOT NULL,
  `short` char(30) NOT NULL,
  `pressure_fluid` int(11) NOT NULL,
  `pressure_confining` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Description of the made experiments';

DROP TABLE IF EXISTS `joinspecimendata`;
CREATE TABLE `joinspecimendata` (
  `specimen_id` smallint(5) UNSIGNED NOT NULL DEFAULT '0',
  `specimen_name` varchar(2500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `height` float(5,2) UNSIGNED DEFAULT NULL,
  `diameter` float(5,2) UNSIGNED DEFAULT NULL,
  `mass_sat` float(8,2) UNSIGNED DEFAULT NULL,
  `mass_wet` float(8,2) UNSIGNED DEFAULT NULL,
  `mass_dry` float(8,2) UNSIGNED DEFAULT NULL,
  `rock_name` varchar(2500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `description` varchar(2500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `density_wet` float(5,3) UNSIGNED DEFAULT NULL,
  `density_sat` float(5,3) UNSIGNED DEFAULT NULL,
  `density_dry` float(5,3) UNSIGNED DEFAULT NULL,
  `density_grain` float(5,3) UNSIGNED DEFAULT NULL,
  `perm_coeff` double UNSIGNED DEFAULT NULL,
  `porosity` float(4,3) UNSIGNED DEFAULT NULL,
  `void_ratio` float(4,3) UNSIGNED DEFAULT NULL,
  `uniAx_comp_strength` int(10) UNSIGNED DEFAULT NULL,
  `uniAx_emodulus` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* Table containing data measured by peekel e.g. temperatures and pressures. 'time' 
	and 'experiment_no' produce the primary key.  */
DROP TABLE IF EXISTS `peekel_data`;
CREATE TABLE `peekel_data` (
  `time` datetime(3) NOT NULL,
  `room_t` float(4,2) DEFAULT NULL,
  `room_p_abs` float(9,6) DEFAULT NULL,
  `fluid_out_t` float(4,2) DEFAULT NULL,
  `fluid_in_t` float(4,2) DEFAULT NULL,
  `fluid_p_abs` float(9,6) DEFAULT NULL,
  `fluid_p_rel` float(9,6) DEFAULT NULL,
  `hydrCylinder_p_abs` float(9,6) DEFAULT NULL,
  `hydrCylinder_p_rel` float(9,6) DEFAULT NULL,
  `sigma2-3_p_abs` float(9,6) DEFAULT NULL,
  `sigma2-3_p_rel` float(9,6) DEFAULT NULL,
  `deformation_1_U` float(10,7) DEFAULT NULL,
  `deformation_1_s_abs` float(10,7) UNSIGNED DEFAULT NULL,
  `deformation_1_s_rel` float(10,7) DEFAULT NULL,
  `deformation_1_s_taravalue` float(10,7) UNSIGNED DEFAULT NULL,
  `deformation_2_U` float(10,7) DEFAULT NULL,
  `deformation_2_s_abs` float(10,7) UNSIGNED DEFAULT NULL,
  `deformation_2_s_rel` float(10,7) DEFAULT NULL,
  `deformation_2_s_taravalue` float(10,7) UNSIGNED DEFAULT NULL,
  `experiment_no` smallint(5) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* Table containing data measured by wille pumps. 'time' and 'experiment_no' produce the 
	primary key. */
DROP TABLE IF EXISTS `pumps_sigma2-3`;
CREATE TABLE `pumps_sigma2-3` (
  `time` datetime(3) NOT NULL,
  `experiment_no` smallint(6) UNSIGNED DEFAULT NULL,
  `runtime` decimal(12,4) UNSIGNED DEFAULT NULL,
  `pump_1_V` float(9,6) DEFAULT NULL,
  `pump_1_p` float(9,6) UNSIGNED DEFAULT NULL,
  `pump_2_V` float(9,6) DEFAULT NULL,
  `pump_2_p` float(9,6) UNSIGNED DEFAULT NULL,
  `pump_3_V` float(9,6) DEFAULT NULL,
  `pump_3_p` float(9,6) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Contains all raw data from the experiments';

/* Table containing rock specific data. Each experiment is connected to a rock dataset 
	implizitly via specimen. */
DROP TABLE IF EXISTS `rock_data`;
CREATE TABLE `rock_data` (
  `id` smallint(5) NOT NULL,
  `name` varchar(2500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `description` varchar(2500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `density_sat` float(5,3) UNSIGNED DEFAULT NULL,
  `density_wet` float(5,3) UNSIGNED DEFAULT NULL,
  `density_dry` float(5,3) UNSIGNED DEFAULT NULL,
  `density_grain` float(5,3) UNSIGNED DEFAULT NULL,
  `perm_coeff` double UNSIGNED DEFAULT NULL,
  `porosity` float(4,3) UNSIGNED DEFAULT NULL,
  `void_ratio` float(4,3) UNSIGNED DEFAULT NULL,
  `uniAx_comp_strength` int(10) UNSIGNED DEFAULT NULL,
  `uniAx_emodulus` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* Table containing scale data like weight. 'time' and 'experiment_no' produce the primary key.*/
DROP TABLE IF EXISTS `scale_fluid`;
CREATE TABLE `scale_fluid` (
  `time` datetime(3) NOT NULL,
  `experiment_no` int(5) UNSIGNED DEFAULT NULL,
  `weight` float(7,6) NOT NULL,
  `runtime` decimal(14,6) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* Table containing specimen related parameters like height or weights. Specimen and experiment are
	connected by 'id'. Rock and specimen are connected by 'rock_id' */
DROP TABLE IF EXISTS `specimen_param`;
CREATE TABLE `specimen_param` (
  `id` smallint(5) UNSIGNED NOT NULL,
  `rock_id` smallint(5) UNSIGNED NOT NULL,
  `name` varchar(2500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `height` float(5,2) UNSIGNED DEFAULT NULL,
  `diameter` float(5,2) UNSIGNED DEFAULT NULL,
  `mass_sat` float(8,2) UNSIGNED DEFAULT NULL,
  `mass_wet` float(8,2) UNSIGNED DEFAULT NULL,
  `mass_dry` float(8,2) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Table containing time logs for each experiment
DROP TABLE IF EXISTS `time_log`;
CREATE TABLE `time_log` (
  `log_id` int(11) NOT NULL,
  `experiment_no` smallint(5) NOT NULL,
  `retrospective` tinyint(1) NOT NULL DEFAULT '0',
  `time` datetime NOT NULL,
  `description` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


ALTER TABLE `data_files`
  ADD PRIMARY KEY (`data_id`);

ALTER TABLE `experiments`
  ADD PRIMARY KEY (`experiment_no`);

ALTER TABLE `peekel_data`
  ADD PRIMARY KEY (`time`);

ALTER TABLE `pumps_sigma2-3`
  ADD PRIMARY KEY (`time`),
  ADD KEY `experiment_no` (`experiment_no`);

ALTER TABLE `rock_data`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `scale_fluid`
  ADD PRIMARY KEY (`time`);

ALTER TABLE `specimen_param`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD UNIQUE KEY `id_2` (`id`);

ALTER TABLE `time_log`
  ADD PRIMARY KEY (`log_id`);

ALTER TABLE `data_files`
  MODIFY `data_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `experiments`
  MODIFY `experiment_no` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `rock_data`
  MODIFY `id` smallint(5) NOT NULL AUTO_INCREMENT;

ALTER TABLE `specimen_param`
  MODIFY `id` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `time_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;
