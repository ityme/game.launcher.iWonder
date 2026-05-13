@echo off
echo.
echo ============================================================
echo  LoL Launcher - Skip-UAC Uninstall
echo ------------------------------------------------------------
echo  This script will:
echo    1. Remove 3 scheduled tasks (wegame / akari / origin)
echo    2. Restore config.json ACL inheritance
echo  Launcher bats will fall back to legacy path (UAC each run).
echo ============================================================
echo.
echo A UAC prompt will appear. Please click "Yes" to authorize once.
echo.
pause

powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoExit -File ""%~dp0core\uninstall-scheduled-tasks.ps1""' -Verb RunAs"
