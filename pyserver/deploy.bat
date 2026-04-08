@echo off
cls

rem Check Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker and try again.
    pause
    exit /b 1
)

rem Deploy
dart C:\users\chris\projects\rpi_deploy\bin\rdDeployAop.dart
pause