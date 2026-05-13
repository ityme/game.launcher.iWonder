# ==========================================================
# 卸载：移除 3 个计划任务，并恢复 config.json 的 ACL 继承
# 必须以管理员身份运行（通过 uninstall-skip-uac.bat 自动唤起 UAC）
# ==========================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Log-State([string]$Tag, [string]$Msg, [ConsoleColor]$Color = "Gray") {
    Write-Host ("[{0}] {1}" -f $Tag, $Msg) -ForegroundColor $Color
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigPath  = Join-Path $ProjectRoot "config.json"

Log-State "Uninstall" "项目根目录: $ProjectRoot" "Cyan"

# --- 1. 卸载三个计划任务 ---
$TaskNames = @("LolLauncher_Wegame", "LolLauncher_Akari", "LolLauncher_Origin")

foreach ($name in $TaskNames) {
    if (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $name -Confirm:$false
        Log-State "OK" "已移除任务: $name" "Green"
    } else {
        Log-State "Skip" "任务不存在: $name" "DarkGray"
    }
}

# --- 2. 恢复 config.json ACL 继承 ---
if (Test-Path $ConfigPath) {
    & icacls.exe $ConfigPath /reset | Out-Null
    & icacls.exe $ConfigPath /inheritance:e | Out-Null
    Log-State "OK" "已恢复 config.json 的 ACL 继承（清除自定义权限）" "Green"
} else {
    Log-State "Skip" "config.json 不存在，无需恢复 ACL" "DarkGray"
}

Write-Host ""
Log-State "Done" "卸载完毕。后续双击 lol-launcher-by-*.bat 将回落到传统启动方式（会弹 UAC）。" "Cyan"
Write-Host ""
pause
