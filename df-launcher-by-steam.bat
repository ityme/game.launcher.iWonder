@echo off
set "CLIENT_TYPE=steam"

powershell -ExecutionPolicy Bypass -File "%~dp0core\df-launcher.ps1" -CLIENT_TYPE "%CLIENT_TYPE%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [LAUNCH ERROR]: Delta Force Steam launcher failed.
    echo   Please check the log above and fix the reported issue.
    echo.
    pause
) else (
    exit
)
