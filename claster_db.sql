SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;


CREATE TABLE IF NOT EXISTS `branches` (
  `branch_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(225) NOT NULL,
  `employed_in_country` int(11) DEFAULT NULL,
  `employed_in_region` int(11) DEFAULT NULL,
  PRIMARY KEY (`branch_id`),
  UNIQUE KEY `name_uniq` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=48 ;

CREATE TABLE IF NOT EXISTS `clasters` (
  `claster_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(125) NOT NULL,
  `link_ref_qualit_analiz` varchar(225) DEFAULT NULL,
  `metrica` enum('mahalonobis','pnorm','ny') NOT NULL DEFAULT 'pnorm',
  `norma` enum('by_sq_deviation','min','max','mean') NOT NULL DEFAULT 'by_sq_deviation',
  `method_single_link` enum('min','max','mean') NOT NULL DEFAULT 'min',
  `pow_pnorm` int(11) NOT NULL DEFAULT '2',
  PRIMARY KEY (`claster_id`),
  UNIQUE KEY `name_uniq` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=117 ;

CREATE TABLE IF NOT EXISTS `companies` (
  `company_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(225) NOT NULL,
  PRIMARY KEY (`company_id`),
  UNIQUE KEY `name_uniq` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=59 ;

CREATE TABLE IF NOT EXISTS `emp_info` (
  `employers_in_country` int(11) NOT NULL,
  `employers_in_region` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `features` (
  `feature_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(225) NOT NULL,
  `units` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`feature_id`),
  UNIQUE KEY `name_uniq` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=71 ;

CREATE TABLE IF NOT EXISTS `rel_clasters_branches` (
  `claster_id` int(11) NOT NULL,
  `branch_id` int(11) NOT NULL,
  PRIMARY KEY (`claster_id`,`branch_id`),
  KEY `branch_id` (`branch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `rel_clasters_companies` (
  `claster_id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  PRIMARY KEY (`claster_id`,`company_id`),
  KEY `foreign_key.id_claster_idx` (`claster_id`),
  KEY `foreign_key.id_company_idx` (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `rel_features_clasters` (
  `claster_id` int(11) NOT NULL,
  `feature_id` int(11) NOT NULL,
  PRIMARY KEY (`claster_id`,`feature_id`),
  KEY `feature_id` (`feature_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `rel_no_clasters_companies` (
  `claster_id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  PRIMARY KEY (`claster_id`,`company_id`),
  KEY `company_id` (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `values_of_features` (
  `company_id` int(11) NOT NULL,
  `feature_id` int(11) NOT NULL,
  `value` double NOT NULL,
  PRIMARY KEY (`company_id`,`feature_id`),
  KEY `feature_id` (`feature_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `weights_of_features` (
  `feature_id` int(11) NOT NULL,
  `claster_id` int(11) NOT NULL,
  `weight` float NOT NULL,
  PRIMARY KEY (`feature_id`,`claster_id`),
  KEY `claster_id` (`claster_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


ALTER TABLE `rel_clasters_branches`
  ADD CONSTRAINT `rel_clasters_branches_ibfk_1` FOREIGN KEY (`claster_id`) REFERENCES `clasters` (`claster_id`),
  ADD CONSTRAINT `rel_clasters_branches_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`branch_id`);

ALTER TABLE `rel_clasters_companies`
  ADD CONSTRAINT `ref_claster` FOREIGN KEY (`claster_id`) REFERENCES `clasters` (`claster_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `ref_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`company_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `rel_features_clasters`
  ADD CONSTRAINT `rel_features_clasters_ibfk_1` FOREIGN KEY (`claster_id`) REFERENCES `clasters` (`claster_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `rel_features_clasters_ibfk_2` FOREIGN KEY (`feature_id`) REFERENCES `features` (`feature_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `rel_no_clasters_companies`
  ADD CONSTRAINT `rel_no_clasters_companies_ibfk_1` FOREIGN KEY (`claster_id`) REFERENCES `clasters` (`claster_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `rel_no_clasters_companies_ibfk_2` FOREIGN KEY (`company_id`) REFERENCES `companies` (`company_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `values_of_features`
  ADD CONSTRAINT `values_of_features_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `companies` (`company_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `values_of_features_ibfk_2` FOREIGN KEY (`feature_id`) REFERENCES `features` (`feature_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `weights_of_features`
  ADD CONSTRAINT `weights_of_features_ibfk_1` FOREIGN KEY (`feature_id`) REFERENCES `features` (`feature_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `weights_of_features_ibfk_2` FOREIGN KEY (`claster_id`) REFERENCES `clasters` (`claster_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
