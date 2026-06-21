@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0core\df-launcher.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [LAUNCH ERROR]: Delta Force launcher failed.
    echo   Please check the log above and fix the reported issue.
    echo.
    pause
) else (
    exit
)
