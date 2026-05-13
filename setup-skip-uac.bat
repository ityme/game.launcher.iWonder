@echo off
echo.
echo ============================================================
echo  LoL Launcher - Skip-UAC Setup (one-time)
echo ------------------------------------------------------------
echo  This script will:
echo    1. Register 3 scheduled tasks (wegame / akari / origin)
echo    2. Harden config.json ACL
echo  After setup, lol-launcher-by-*.bat will run without UAC prompts.
echo ============================================================
echo.
echo A UAC prompt will appear. Please click "Yes" to authorize once.
echo.
pause

powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoExit -File ""%~dp0core\setup-scheduled-tasks.ps1""' -Verb RunAs"
