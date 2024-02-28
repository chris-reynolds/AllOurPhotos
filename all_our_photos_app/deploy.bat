@echo off
cls
rem first check your starting point
c:
cd \projects\all*os\all*app

rem now map the z: drive
if not exist z:\software net use z: \\rpi4.local\aop

rem now do the copy
robocopy  build\web z:\software\client /e

echo 

pause

