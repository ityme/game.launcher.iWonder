@echo off
set "CLIENT_TYPE=wegame"


powershell -ExecutionPolicy Bypass -File "%~dp0core\lol-launcher.ps1" -CLIENT_TYPE "%CLIENT_TYPE%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ENV ERROR]: can't find core file: lol-launcher.ps1
    echo   Please run the .bat file from its original project folder.
    echo     Do not move or copy it elsewhere!
    echo.
    pause
) else (
    exit
)
