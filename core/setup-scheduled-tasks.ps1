# ==========================================================
# 一次性安装：注册三个免 UAC 计划任务，并加固 config.json ACL
# 必须以管理员身份运行（通过 setup-skip-uac.bat 自动唤起 UAC）
# ==========================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Log-State([string]$Tag, [string]$Msg, [ConsoleColor]$Color = "Gray") {
    Write-Host ("[{0}] {1}" -f $Tag, $Msg) -ForegroundColor $Color
}

# --- 路径解析 ---
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Ps1Path     = Join-Path $PSScriptRoot "lol-launcher.ps1"
$ConfigPath  = Join-Path $ProjectRoot "config.json"

if (-not (Test-Path $Ps1Path)) {
    Log-State "FATAL" "找不到核心脚本: $Ps1Path" "Red"
    pause
    exit 1
}

Log-State "Setup" "项目根目录: $ProjectRoot" "Cyan"

# --- 1. 注册三个计划任务 ---
$Tasks = @(
    @{ Name = "LolLauncher_Wegame"; ClientType = "wegame" },
    @{ Name = "LolLauncher_Akari";  ClientType = "akari"  },
    @{ Name = "LolLauncher_Origin"; ClientType = "origin" }
)

# 任务实际以谁的身份运行：用启动 UAC 之前的"原始用户"，而不是当前管理员令牌。
# WhoAmI 在被 RunAs 提权后仍返回原用户名时，可直接用 $env:USERNAME；
# 但稳妥起见，从 LOGONSERVER + USERDOMAIN 组合，并回退到 USERNAME。
$RunAsUser = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }

foreach ($t in $Tasks) {
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$Ps1Path`" -CLIENT_TYPE $($t.ClientType)" `
        -WorkingDirectory $ProjectRoot

    $Principal = New-ScheduledTaskPrincipal `
        -UserId $RunAsUser `
        -LogonType Interactive `
        -RunLevel Highest

    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -MultipleInstances IgnoreNew

    if (Get-ScheduledTask -TaskName $t.Name -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $t.Name -Confirm:$false
        Log-State "Refresh" "已移除旧任务: $($t.Name)" "DarkGray"
    }

    Register-ScheduledTask `
        -TaskName $t.Name `
        -Action $Action `
        -Principal $Principal `
        -Settings $Settings `
        -Description "LoL 启动器（CLIENT_TYPE=$($t.ClientType)）— 免 UAC 执行" `
        | Out-Null

    Log-State "OK" "已注册任务: $($t.Name) (RunLevel=Highest, User=$RunAsUser)" "Green"
}

# --- 2. 加固 config.json ACL ---
if (Test-Path $ConfigPath) {
    # 移除继承 + 仅授予当前用户、SYSTEM、Administrators 完全控制
    & icacls.exe $ConfigPath /inheritance:r | Out-Null
    & icacls.exe $ConfigPath /grant "$($env:USERNAME):F" "SYSTEM:F" "Administrators:F" | Out-Null
    Log-State "OK" "已加固 config.json ACL（仅 $env:USERNAME / SYSTEM / Administrators 可写）" "Green"
} else {
    Log-State "Warn" "config.json 尚不存在；首次运行启动器生成后可重跑本脚本完成 ACL 加固。" "Yellow"
}

Write-Host ""
Log-State "Done" "设置完毕。后续双击 lol-launcher-by-*.bat 将不再弹 UAC。" "Cyan"
Write-Host ""
pause
