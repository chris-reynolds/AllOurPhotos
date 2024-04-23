#SELECT file_name FROM aopsnaps WHERE import_source LIKE 'crop%'
# SELECT id,device_name,metadata,coalesce(JSON_EXTRACT(metadata,'$.ExifImageWidth'),JSON_EXTRACT(metadata,'$.ImageWidth')),coalesce(JSON_EXTRACT(metadata,'$.ExifImageHeight'),JSON_EXTRACT(metadata,'$.ImageLength')) FROM aopsnaps where imported_date > '2024-03-01'

update aopsnaps set width=coalesce(JSON_EXTRACT(metadata,'$.ExifImageWidth'),JSON_EXTRACT(metadata,'$.ImageWidth')),
	height=coalesce(JSON_EXTRACT(metadata,'$.ExifImageHeight'),JSON_EXTRACT(metadata,'$.ImageLength')) where imported_date > '2024-03-01'

