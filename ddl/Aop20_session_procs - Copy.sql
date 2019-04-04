-- DDL (Stored Procedure) Generation for Aop
-- Target Database is mySql + dart + flutter

--                                '*** Start Custom Code database connect
--                                '*** End Custom Code
delimiter @@
-- Table aopalbums
  --   
drop trigger if exists aopalbums_before_ins@@
CREATE TRIGGER aopalbums_before_ins BEFORE INSERT ON aopalbums FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.session_id = (select id from current_session);
  set new.updated_user =(select username from current_session);
  set new.user_id = (select userid from current_session);
END @@  

drop trigger if exists aopalbums_before_upd@@
CREATE TRIGGER aopalbums_before_upd BEFORE UPDATE ON aopalbums FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from current_session);
END @@

-- Table aopalbum_items
  --   
drop trigger if exists aopalbum_items_before_ins@@
CREATE TRIGGER aopalbum_items_before_ins BEFORE INSERT ON aopalbum_items FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.session_id = (select id from current_session);
  set new.updated_user =(select username from current_session);
  set new.user_id = (select userid from current_session);
END @@  

drop trigger if exists aopalbum_items_before_upd@@
CREATE TRIGGER aopalbum_items_before_upd BEFORE UPDATE ON aopalbum_items FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from current_session);
END @@

-- Table aopimages
  --   
drop trigger if exists aopimages_before_ins@@
CREATE TRIGGER aopimages_before_ins BEFORE INSERT ON aopimages FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.session_id = (select id from current_session);
  set new.updated_user =(select username from current_session);
  set new.user_id = (select userid from current_session);
END @@  

drop trigger if exists aopimages_before_upd@@
CREATE TRIGGER aopimages_before_upd BEFORE UPDATE ON aopimages FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from current_session);
END @@

-- Table aopsessions
  --   
drop trigger if exists aopsessions_before_ins@@
CREATE TRIGGER aopsessions_before_ins BEFORE INSERT ON aopsessions FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.session_id = (select id from current_session);
  set new.updated_user =(select username from current_session);
  set new.user_id = (select userid from current_session);
END @@  

drop trigger if exists aopsessions_before_upd@@
CREATE TRIGGER aopsessions_before_upd BEFORE UPDATE ON aopsessions FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from current_session);
END @@

-- Table aopsnaps
  --   
drop trigger if exists aopsnaps_before_ins@@
CREATE TRIGGER aopsnaps_before_ins BEFORE INSERT ON aopsnaps FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.session_id = (select id from current_session);
  set new.updated_user =(select username from current_session);
  set new.user_id = (select userid from current_session);
END @@  

drop trigger if exists aopsnaps_before_upd@@
CREATE TRIGGER aopsnaps_before_upd BEFORE UPDATE ON aopsnaps FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from current_session);
END @@

-- Table aopusers
  --   This indicates who can edit the pictures
drop trigger if exists aopusers_before_ins@@
CREATE TRIGGER aopusers_before_ins BEFORE INSERT ON aopusers FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.session_id = (select id from current_session);
  set new.updated_user =(select username from current_session);
  set new.user_id = (select userid from current_session);
END @@  

drop trigger if exists aopusers_before_upd@@
CREATE TRIGGER aopusers_before_upd BEFORE UPDATE ON aopusers FOR EACH ROW BEGIN
  set new.updated_on = now();
  set new.updated_user =(select username from current_session);
END @@

