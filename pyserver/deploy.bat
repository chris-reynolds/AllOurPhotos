@echo off
cls
rem first check your starting point
c:
cd \projects\all*os\pyserver

rem now map the z: drive
if not exist z:\software net use z: \\rpi4.local\aop

rem now do the copy
robocopy  src z:\software\server\src *.py /e

set /p 

pause