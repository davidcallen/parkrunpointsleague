USE PRPL;

CREATE TABLE ATHLETE (
	ID                              INTEGER UNSIGNED,
	FIRST_NAME                      VARCHAR(50) NULL,
	LAST_NAME                       VARCHAR(50) NULL,
	GENDER                          VARCHAR(1)  NOT NULL,
	PRIMARY KEY (ID)
) ENGINE=InnoDB;

CREATE TABLE EVENT (
	ID                              INTEGER UNSIGNED AUTO_INCREMENT,
	NAME                            VARCHAR(300) NOT NULL,
	TITLE                           VARCHAR(300) NOT NULL,
	BIRTHDAY                        DATE,
	PRIMARY KEY (ID),
	UNIQUE KEY (NAME)
) ENGINE=InnoDB;

CREATE TABLE EVENT_RESULT (
	ID                              INTEGER UNSIGNED AUTO_INCREMENT,
	EVENT_ID                        INTEGER UNSIGNED NOT NULL,
	RESULT_NUMBER                   INTEGER UNSIGNED NOT NULL,
	DATE                            DATE NOT NULL,
	LEAGUE_YEAR                     INTEGER UNSIGNED,
	PRIMARY KEY (ID),
	UNIQUE KEY (EVENT_ID, RESULT_NUMBER)
) ENGINE=InnoDB;

CREATE TABLE EVENT_RESULT_ITEM (
	ID                 				INTEGER UNSIGNED AUTO_INCREMENT,
	EVENT_RESULT_ID                 INTEGER UNSIGNED NOT NULL,
	POSITION                        INTEGER UNSIGNED NOT NULL,
	GENDER_POSITION                 INTEGER UNSIGNED NULL,
	GENDER                          VARCHAR(1) NOT NULL,
	ATHLETE_ID                      INTEGER UNSIGNED,
	DURATION_SECS                   INTEGER UNSIGNED,
	PRIMARY KEY (ID),
	UNIQUE KEY (EVENT_RESULT_ID, POSITION)
) ENGINE=InnoDB;

CREATE TABLE EVENT_LEAGUE (
	ID                              INTEGER UNSIGNED AUTO_INCREMENT,
	EVENT_ID                        INTEGER UNSIGNED NOT NULL,
	YEAR                            INTEGER UNSIGNED NOT NULL,
	LATEST_EVENT_RESULT_ID          INTEGER UNSIGNED NOT NULL,
	PRIMARY KEY (ID),
	UNIQUE KEY EVENT_LEAGUE__EVENT_ID_YEAR (EVENT_ID, YEAR)
) ENGINE=InnoDB;

CREATE TABLE EVENT_LEAGUE_ITEM (
	ID                              INTEGER UNSIGNED AUTO_INCREMENT,
	EVENT_LEAGUE_ID                 INTEGER UNSIGNED NOT NULL,
	POSITION                        INTEGER UNSIGNED NOT NULL,
	GENDER_POSITION                 INTEGER UNSIGNED NOT NULL,
	GENDER                          VARCHAR(1) NOT NULL,
	ATHLETE_ID                      INTEGER UNSIGNED NOT NULL,
	POINTS                          INTEGER UNSIGNED NOT NULL,
	RUN_COUNT                       INTEGER UNSIGNED NOT NULL,
	PRIMARY KEY (ID),
	UNIQUE KEY EVENT_LEAGUE_ITEM__EVENT_LEAGUE_ID_ATHLETE_ID (EVENT_LEAGUE_ID, ATHLETE_ID),
	UNIQUE KEY EVENT_LEAGUE_ITEM__EVENT_LEAGUE_ID_POSITION (EVENT_LEAGUE_ID, POSITION)
) ENGINE=InnoDB;

CREATE TABLE PARAM (
	NAME                            VARCHAR(100) NOT NULL,
	VALUE							VARCHAR(500) NULL,
	PRIMARY KEY (NAME)
) ENGINE=InnoDB;

GRANT ALL ON PRPL.* TO 'PRPL'@'localhost';

insert into PARAM (NAME, VALUE) values ('SCHEMA_VERSION', '0.1.0.0');
