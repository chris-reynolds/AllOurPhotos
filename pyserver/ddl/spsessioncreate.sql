USE allourphotos;
delimiter $$;
CREATE FUNCTION `spsessioncreate`(
	`in_name` VARCHAR(50),
	`in_hint` VARCHAR(50),
	`in_source` VARCHAR(50)
)
RETURNS int(11)
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
END;
$$

