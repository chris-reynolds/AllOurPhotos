#SELECT CONCAT('<',rotation,'>'),degrees,COUNT(*) FROM aopsnaps GROUP BY 1,2;
DELETE FROM aopsnaps WHERE filename='P5074819.JPG' OR filename='20230510_111443.jpg' OR filename='IMG_20230511_172050.jpg'
#update aopsnaps SET DEGREES=270 WHERE rotation='1' ;
#update aopsnaps SET DEGREES=180 WHERE rotation='2' ;
#update aopsnaps SET DEGREES=90 WHERE rotation='3' ;
#update aopsnaps SET DEGREES=0 WHERE rotation=0 AND DEGREES<>0 ;
#update aopsnaps SET rotation=0 WHERE rotation=91 ;

COMMIT;