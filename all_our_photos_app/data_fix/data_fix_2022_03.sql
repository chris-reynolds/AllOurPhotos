-- identify which photos have different metadata entries for DateTime and DateTimeOriginal
select Datediff(original_taken_date,coalesce(str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y-%m-%d %H:%i:%s'),str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y:%m:%d %H:%i:%s'))),
  coalesce(str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y-%m-%d %H:%i:%s'),str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y:%m:%d %H:%i:%s')),
  str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y:%m:%d %H:%i:%s'),json_value(metadata,'$.DateTime'),aopsnaps.* from aopsnaps
 where json_value(metadata,'$.DateTimeOriginal') is not null and json_value(metadata,'$.DateTimeOriginal')<> json_value(metadata,'$.DateTime')
 and Datediff(original_taken_date,coalesce(str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y-%m-%d %H:%i:%s'),str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y:%m:%d %H:%i:%s')))>0
 -- and (Datediff(taken_date,str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y-%m-%d %H:%i:%s'))>0 or Datediff(taken_date,str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y:%m:%d %H:%i:%s'))>0 )
 order by 1 desc   ;

 -- now fix the data
 update aopsnaps set original_taken_date =
  coalesce(str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y-%m-%d %H:%i:%s'),str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y:%m:%d %H:%i:%s'))
  where json_value(metadata,'$.DateTimeOriginal') is not null and json_value(metadata,'$.DateTimeOriginal')<> json_value(metadata,'$.DateTime')
  and Datediff(original_taken_date,coalesce(str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y-%m-%d %H:%i:%s'),str_to_date(json_value(metadata,'$.DateTimeOriginal'),'%Y:%m:%d %H:%i:%s')))>0

Error Code: 1175. You are using safe update mode and you tried to update a table without a WHERE that uses a KEY column To disable safe mode, toggle the option in Preferences -> SQL Editor and reconnect.
