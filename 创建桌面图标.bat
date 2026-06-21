@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0core\create-shortcuts.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo.
    echo [SHORTCUT ERROR] Failed to create shortcuts.
    echo   Please check the messages above and run this file again.
    echo.
    pause
)

exit /b %EXIT_CODE%
