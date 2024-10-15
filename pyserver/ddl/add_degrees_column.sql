SELECT rotation,DEGREES,COUNT(*) FROM aopsnaps GROUP BY 1,2;

# update aopsnaps SET DEGREES=90 WHERE rotation=1 AND DEGREES=0;
# update aopsnaps SET DEGREES=180 WHERE rotation=2 AND DEGREES=0;
# update aopsnaps SET DEGREES=270 WHERE rotation=3 AND DEGREES=0;
