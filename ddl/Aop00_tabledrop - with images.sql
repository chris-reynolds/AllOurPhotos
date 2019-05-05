-- DDL (Table Drop) Generation for Aop
-- Target Database is mySql + dart + flutter

--                                '*** Start Custom Code database connect
--use allourphotos;
drop function if exists spsessioncreate;
--                                '*** End Custom Code

-- Table aopalbums
drop table if exists aopalbums;
-- Table aopalbum_items
drop table if exists aopalbum_items;
-- Table aopfull_images
drop table if exists aopfull_images;
-- Table aopsessions
drop table if exists aopsessions;
-- Table aopsnaps
drop table if exists aopsnaps;
-- Table aopthumbnails
drop table if exists aopthumbnails;
-- Table aopusers
drop table if exists aopusers;
-- todo referential integrity drop
-- Drop Table Script Finished 


