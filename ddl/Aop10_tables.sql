-- DDL (Table) Generation for Aop
-- Target Database is mySql + dart + flutter

--                                '*** Start Custom Code database connect
--use allourphotos;
--                                '*** End Custom Code

-- Table aopalbums
  --   
--  ' > CREATING - aopalbums ...'
DROP TABLE IF EXISTS aopalbums ;
CREATE TABLE aopalbums (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , created_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_user         varchar(30) not null
  , name Varchar(50) not Null
  , description Varchar(250) 
  , first_date Datetime 
  , last_date Datetime 
  ,  user_id Int NULL
); 

-- Table aopalbum_items
  --   
--  ' > CREATING - aopalbum_items ...'
DROP TABLE IF EXISTS aopalbum_items ;
CREATE TABLE aopalbum_items (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , created_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_user         varchar(30) not null
  ,  album_id Int NULL
  ,  snap_id Int NULL
); 

-- Table aopsessions
  --   
--  ' > CREATING - aopsessions ...'
DROP TABLE IF EXISTS aopsessions ;
CREATE TABLE aopsessions (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , created_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_user         varchar(30) not null
  , session_status      varchar(30)
  , start_date Datetime 
  , end_date Datetime 
  , source Varchar(30) 
  ,  user_id Int NULL
); 

-- Table aopsnaps
  --   
--  ' > CREATING - aopsnaps ...'
DROP TABLE IF EXISTS aopsnaps ;
CREATE TABLE aopsnaps (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , created_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_user         varchar(30) not null
  , file_name Varchar(100) 
  , directory Varchar(100) 
  , taken_date Datetime 
  , original_taken_date Datetime 
  , modified_date Datetime 
  , device_name Varchar(100) 
  , caption Varchar(100) 
  , ranking INT not Null
  , longitude Float 
  , latitude Float 
  , width INT 
  , height INT 
  , location Varchar(200) 
  , rotation Varchar(30) 
  , import_source Varchar(50) 
  , media_type Varchar(30) not Null
  , imported_date Datetime 
  , media_length INT 
  , tag_list Varchar(250) 
  , metadata Varchar(32000) 
  ,  session_id Int NULL
  ,  user_id Int NULL
); 

-- Table aopusers
  --   This indicates who can edit the pictures
--  ' > CREATING - aopusers ...'
DROP TABLE IF EXISTS aopusers ;
CREATE TABLE aopusers (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , created_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_on      DATETIME not null DEFAULT CURRENT_TIMESTAMP
  , updated_user         varchar(30) not null
  , name Varchar(30) not Null
  , hint Varchar(20) 
); 



/* comment out for now
ALTER TABLE aopalbums ADD CONSTRAINT fk_album_user
  FOREIGN KEY fk_user(user_id)
  references aopusers(ID);
ALTER TABLE aopalbum_items ADD CONSTRAINT fk_album_item_album
  FOREIGN KEY fk_album(album_id)
  references aopalbums(ID);
ALTER TABLE aopalbum_items ADD CONSTRAINT fk_album_item_snap
  FOREIGN KEY fk_snap(snap_id)
  references aopsnaps(ID);
ALTER TABLE aopsessions ADD CONSTRAINT fk_session_user
  FOREIGN KEY fk_user(user_id)
  references aopusers(ID);
ALTER TABLE aopsnaps ADD CONSTRAINT fk_snap_session
  FOREIGN KEY fk_session(session_id)
  references aopsessions(ID);
ALTER TABLE aopsnaps ADD CONSTRAINT fk_snap_user
  FOREIGN KEY fk_user(user_id)
  references aopusers(ID);
*/ 
-- '   > ALTER - add uniqueness for column name to aopalbums table ...'
ALTER TABLE aopalbums
ADD
  CONSTRAINT aopalbums_uq1 UNIQUE NONCLUSTERED (name);
-- '   > ALTER - add composite uniqueness constraint to aopsnaps table ...'
ALTER TABLE aopsnaps
ADD
  CONSTRAINT aopsnaps_compuq UNIQUE NONCLUSTERED ( file_name,  media_length);
-- '   > ALTER - add uniqueness for column name to aopusers table ...'
ALTER TABLE aopusers
ADD
  CONSTRAINT aopusers_uq1 UNIQUE NONCLUSTERED (name);

-- Table Creation Script Finished

--                                '*** Start Custom Code populatetestdata
create index aopsnap_nondup on aopsnaps(original_taken_date,media_length);
INSERT INTO `aopusers` (`updated_user`, `name`, `hint`) VALUES ('maxim', 'chris', 'chris00');
INSERT INTO `aopusers` (`updated_user`, `name`, `hint`) VALUES ('maxim', 'janet', 'janet00');

--                                '*** End Custom Code


