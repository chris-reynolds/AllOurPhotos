-- DDL (Table) Generation for Aop
-- Target Database is mySql + Ruby on Rails


-- Table aopalbums
  --   
--  ' > CREATING - aopalbums ...'
DROP TABLE IF EXISTS aopalbums ;
CREATE TABLE aopalbums (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , updated_on      DATETIME
  , updated_user         varchar(30) not null
--  , lock_version    int default 0
  , conversion_id   int
  , name Varchar(50) 
  , description Varchar(250) 
  ,  owner_id INT NULL
); 

-- Table aopalbum_itemses
  --   
--  ' > CREATING - aopalbum_itemses ...'
DROP TABLE IF EXISTS aopalbum_itemses ;
CREATE TABLE aopalbum_itemses (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , updated_on      DATETIME
  , updated_user         varchar(30) not null
--  , lock_version    int default 0
  , conversion_id   int
  , fred Int 
  ,  album_id INT NULL
  ,  image_id INT NULL
); 

-- Table aopimages
  --   
--  ' > CREATING - aopimages ...'
DROP TABLE IF EXISTS aopimages ;
CREATE TABLE aopimages (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , updated_on      DATETIME
  , updated_user         varchar(30) not null
--  , lock_version    int default 0
  , conversion_id   int
  , file_name Varchar(100) 
  , directory Varchar(30) 
  , taken_date Datetime 
  , modified_date Datetime 
  , device_name Varchar(100) 
  , caption Varchar(100) 
  , ranking INT not Null
  , longitude Float 
  , latitude Float 
  , rotation Varchar(30) 
  , import_source Varchar(50) 
  , has_thumbnail YesNo not Null
  , tag_list Varchar(250) 
  ,  owner_id INT NULL
  ,  source_image_id INT NULL
); 

-- Table aopowners
  --   This indicates who can edit the pictures
--  ' > CREATING - aopowners ...'
DROP TABLE IF EXISTS aopowners ;
CREATE TABLE aopowners (
  id             INT AUTO_INCREMENT Not null PRIMARY KEY 
  , updated_on      DATETIME
  , updated_user         varchar(30) not null
--  , lock_version    int default 0
  , conversion_id   int
  , name Varchar(30) 
); 


/* comment out

/*
/* Comment out
-- Table aopalbums_audit
  --   
-- '   > CREATING - aopalbums_audit ...'
DROP TABLE IF EXISTS aopalbums_audit ;
CREATE TABLE aopalbums_audit (
  ID             INT Not null
  , updated_on      DATETIME Not null
  , updated_user    varchar(30)
  , lock_version    int default 0
  , name Varchar(50) 
  , description Varchar(250) 
  , owner_id INT NULL
  ,PRIMARY KEY (ID,updated_on)
)  ENGINE=InnoDB;

-- Table aopalbum_itemses_audit
  --   
-- '   > CREATING - aopalbum_itemses_audit ...'
DROP TABLE IF EXISTS aopalbum_itemses_audit ;
CREATE TABLE aopalbum_itemses_audit (
  ID             INT Not null
  , updated_on      DATETIME Not null
  , updated_user    varchar(30)
  , lock_version    int default 0
  , fred Int 
  , album_id INT NULL
  , image_id INT NULL
  ,PRIMARY KEY (ID,updated_on)
)  ENGINE=InnoDB;

-- Table aopimages_audit
  --   
-- '   > CREATING - aopimages_audit ...'
DROP TABLE IF EXISTS aopimages_audit ;
CREATE TABLE aopimages_audit (
  ID             INT Not null
  , updated_on      DATETIME Not null
  , updated_user    varchar(30)
  , lock_version    int default 0
  , file_name Varchar(100) 
  , directory Varchar(30) 
  , taken_date Datetime 
  , modified_date Datetime 
  , device_name Varchar(100) 
  , caption Varchar(100) 
  , ranking INT not Null
  , longitude Float 
  , latitude Float 
  , rotation Varchar(30) 
  , import_source Varchar(50) 
  , has_thumbnail YesNo not Null
  , tag_list Varchar(250) 
  , owner_id INT NULL
  , source_image_id INT NULL
  ,PRIMARY KEY (ID,updated_on)
)  ENGINE=InnoDB;

-- Table aopowners_audit
  --   This indicates who can edit the pictures
-- '   > CREATING - aopowners_audit ...'
DROP TABLE IF EXISTS aopowners_audit ;
CREATE TABLE aopowners_audit (
  ID             INT Not null
  , updated_on      DATETIME Not null
  , updated_user    varchar(30)
  , lock_version    int default 0
  , name Varchar(30) 
  ,PRIMARY KEY (ID,updated_on)
)  ENGINE=InnoDB;

/*

/* comment out for now
ALTER TABLE aopalbums ADD CONSTRAINT fk_album_owner
  FOREIGN KEY fk_owner(owner_id)
  references aopowners(ID);
ALTER TABLE aopalbum_itemses ADD CONSTRAINT fk_album_items_album
  FOREIGN KEY fk_album(album_id)
  references aopalbums(ID);
ALTER TABLE aopalbum_itemses ADD CONSTRAINT fk_album_items_image
  FOREIGN KEY fk_image(image_id)
  references aopimages(ID);
ALTER TABLE aopimages ADD CONSTRAINT fk_image_owner
  FOREIGN KEY fk_owner(owner_id)
  references aopowners(ID);
ALTER TABLE aopimages ADD CONSTRAINT fk_image_source_image
  FOREIGN KEY fk_source_image(source_image_id)
  references aopimages(ID);
*/ 

-- Table Creation Script Finished

--                                '*** Start Custom Code populatetestdata
--                                '*** End Custom Code


