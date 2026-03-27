@echo off
set "CLIENT_TYPE=akari"


powershell -ExecutionPolicy Bypass -File "%~dp0core\lol-launcher.ps1" -CLIENT_TYPE "%CLIENT_TYPE%"

exit
