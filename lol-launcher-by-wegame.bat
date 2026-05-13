@echo off
setlocal
set "CLIENT_TYPE=wegame"
set "TASK_NAME=LolLauncher_Wegame"
set "CORE_PS1=%~dp0core\lol-launcher.ps1"

REM --- 1. 核心文件存在性校验 ---
if not exist "%CORE_PS1%" (
    echo.
    echo [ENV ERROR]: can't find core file: lol-launcher.ps1
    echo   Please run the .bat file from its original project folder.
    echo     Do not move or copy it elsewhere!
    echo.
    pause
    exit /b 1
)

REM --- 2. 优先走免 UAC 路径（计划任务已注册时） ---
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    schtasks /run /tn "%TASK_NAME%"
    exit /b 0
)

REM --- 3. fallback: task not registered, use legacy path (UAC will prompt) ---
echo [INFO] Scheduled task "%TASK_NAME%" not found. Using legacy path (UAC prompt each run).
echo        For skip-UAC mode, double-click setup-skip-uac.bat once to install.
echo.
powershell -ExecutionPolicy Bypass -File "%CORE_PS1%" -CLIENT_TYPE "%CLIENT_TYPE%"
endlocal
