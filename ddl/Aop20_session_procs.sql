-- DDL (Stored Procedure) Generation for Aop
-- Target Database is mySql + dart + flutter

--                                '*** Start Custom Code database connect
-- use allourphotos;

--                                '*** End Custom Code

delimiter @@
drop function if exists spsessioncreate@@

CREATE FUNCTION `spsessioncreate`(
	`in_name` VARCHAR(50),
	`in_hint` VARCHAR(50),
	`in_source` VARCHAR(50)
)
RETURNS int(11)
LANGUAGE SQL
NOT DETERMINISTIC
CONTAINS SQL
SQL SECURITY DEFINER
COMMENT ''
BEGIN
  declare _userid int;
  declare _sessionid int;
  drop temporary table if exists currentsession;
  select id into _userid
    from aopusers where name=in_name and hint=in_hint;
  if _userid>0 then
      set _sessionid = -1;
    insert into aopsessions( updated_user, start_date, source, user_id)
    	values(in_name,now(),in_source,_userid);
   	select last_insert_id() into _sessionid;
   	create temporary table currentsession(username varchar(50),session_id int,user_id int);
   	insert into currentsession values(in_name,_sessionid,_userid);
  else
    set _sessionid = -1;
  end if;	  
  return _sessionid; 
END;@@


-- Table aopalbums
  --   
drop trigger if exists aopalbums_before_ins@@
CREATE TRIGGER aopalbums_before_ins BEFORE INSERT ON aopalbums FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
END @@  

drop trigger if exists aopalbums_before_upd@@
CREATE TRIGGER aopalbums_before_upd BEFORE UPDATE ON aopalbums FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from currentsession);
END @@

-- Table aopalbum_items
  --   
drop trigger if exists aopalbum_items_before_ins@@
CREATE TRIGGER aopalbum_items_before_ins BEFORE INSERT ON aopalbum_items FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
END @@  

drop trigger if exists aopalbum_items_before_upd@@
CREATE TRIGGER aopalbum_items_before_upd BEFORE UPDATE ON aopalbum_items FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from currentsession);
END @@

-- Table aopfull_images
  --   
drop trigger if exists aopfull_images_before_ins@@
CREATE TRIGGER aopfull_images_before_ins BEFORE INSERT ON aopfull_images FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
END @@  

drop trigger if exists aopfull_images_before_upd@@
CREATE TRIGGER aopfull_images_before_upd BEFORE UPDATE ON aopfull_images FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from currentsession);
END @@

-- Table aopsessions
  --   
drop trigger if exists aopsessions_before_ins@@
CREATE TRIGGER aopsessions_before_ins BEFORE INSERT ON aopsessions FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
END @@  

drop trigger if exists aopsessions_before_upd@@
CREATE TRIGGER aopsessions_before_upd BEFORE UPDATE ON aopsessions FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from currentsession);
END @@

-- Table aopsnaps
  --   
drop trigger if exists aopsnaps_before_ins@@
CREATE TRIGGER aopsnaps_before_ins BEFORE INSERT ON aopsnaps FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
END @@  

drop trigger if exists aopsnaps_before_upd@@
CREATE TRIGGER aopsnaps_before_upd BEFORE UPDATE ON aopsnaps FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from currentsession);
END @@

-- Table aopthumbnails
  --   
drop trigger if exists aopthumbnails_before_ins@@
CREATE TRIGGER aopthumbnails_before_ins BEFORE INSERT ON aopthumbnails FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
END @@  

drop trigger if exists aopthumbnails_before_upd@@
CREATE TRIGGER aopthumbnails_before_upd BEFORE UPDATE ON aopthumbnails FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from currentsession);
END @@

-- Table aopusers
  --   This indicates who can edit the pictures
drop trigger if exists aopusers_before_ins@@
CREATE TRIGGER aopusers_before_ins BEFORE INSERT ON aopusers FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
END @@  

drop trigger if exists aopusers_before_upd@@
CREATE TRIGGER aopusers_before_upd BEFORE UPDATE ON aopusers FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from currentsession);
END @@


--                                '*** Start Custom Code finish
drop trigger if exists aopsessions_before_ins@@
drop trigger if exists aopsessions_before_upd@@
drop trigger if exists aopsnaps_before_ins@@
CREATE TRIGGER aopsnaps_before_ins BEFORE INSERT ON aopsnaps FOR EACH ROW BEGIN
  set new.created_on = now();
  set new.updated_on = new.updated_on;
  set new.updated_user =(select username from currentsession);
  set new.user_id = (select user_id from currentsession);
  set new.session_id = (select session_id from currentsession);
END @@  
--                                '*** End Custom Code
