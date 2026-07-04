# ==========================================================
# Create desktop and Start Menu shortcuts
# ==========================================================

$ErrorActionPreference = "Stop"

function Log-State([string]$Tag, [string]$Msg, [ConsoleColor]$Color = "Gray") {
    Write-Host ("[{0}] {1}" -f $Tag, $Msg) -ForegroundColor $Color
}

function Get-Fallback-Path([string]$Primary, [string]$Fallback) {
    if ([string]::IsNullOrWhiteSpace($Primary)) {
        return $Fallback
    }
    return $Primary
}

function New-Launcher-Shortcut($Shell, [string]$Name, [string]$TargetPath, [string]$IconPath, [string]$DestinationDir, [string]$ProjectRoot) {
    if (-not (Test-Path $TargetPath)) {
        throw "Target file not found: $TargetPath"
    }

    if (-not (Test-Path $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    }

    $linkPath = Join-Path $DestinationDir ("{0}.lnk" -f $Name)
    $shortcut = $Shell.CreateShortcut($linkPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = $ProjectRoot
    $shortcut.Description = "game.launcher.iWonder - $Name"

    if (Test-Path $IconPath) {
        $shortcut.IconLocation = "{0},0" -f $IconPath
    } else {
        Log-State "图标缺失" "未找到图标文件: $IconPath" "Yellow"
    }

    $shortcut.Save()
    Log-State "创建成功" "$Name -> $DestinationDir" "Green"
}

$PROJECT_ROOT = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$desktopDir = Get-Fallback-Path `
    ([Environment]::GetFolderPath("DesktopDirectory")) `
    (Join-Path $env:USERPROFILE "Desktop")

$programsRoot = Get-Fallback-Path `
    ([Environment]::GetFolderPath("Programs")) `
    (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs")

$startMenuDir = Join-Path $programsRoot "game.launcher.iWonder"

$shortcuts = @(
    @{
        Name = "lol-origin"
        Target = "lol-launcher-by-origin.bat"
        Icon = "assets\icon\lol.ico"
    },
    @{
        Name = "lol-akari"
        Target = "lol-launcher-by-akari.bat"
        Icon = "assets\icon\lol.ico"
    },
    @{
        Name = "df-origin"
        Target = "df-launcher-by-origin.bat"
        Icon = "assets\icon\df.ico"
    },
    @{
        Name = "df-steam"
        Target = "df-launcher-by-steam.bat"
        Icon = "assets\icon\df.ico"
    }
)

Log-State "快捷方式" "正在创建桌面与开始菜单快捷方式..." "Cyan"
Log-State "项目目录" $PROJECT_ROOT "DarkGray"

$shell = New-Object -ComObject WScript.Shell

try {
    foreach ($item in $shortcuts) {
        $targetPath = Join-Path $PROJECT_ROOT $item.Target
        $iconPath = Join-Path $PROJECT_ROOT $item.Icon

        New-Launcher-Shortcut `
            -Shell $shell `
            -Name $item.Name `
            -TargetPath $targetPath `
            -IconPath $iconPath `
            -DestinationDir $desktopDir `
            -ProjectRoot $PROJECT_ROOT

        New-Launcher-Shortcut `
            -Shell $shell `
            -Name $item.Name `
            -TargetPath $targetPath `
            -IconPath $iconPath `
            -DestinationDir $startMenuDir `
            -ProjectRoot $PROJECT_ROOT
    }
} finally {
    if ($shell) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
}

Write-Host ""
Log-State "完成" "桌面快捷方式已创建: $desktopDir" "Green"
Log-State "完成" "开始菜单快捷方式已创建: $startMenuDir" "Green"
Log-State "提示" "移动项目目录后, 重新运行 创建桌面图标.bat 即可刷新路径。" "Yellow"

Write-Host ""
for ($i = 3; $i -gt 0; $i--) {
    Write-Host ("`r[脚本结束] 执行完毕, 将在 {0} 秒后自动退出..." -f $i) -ForegroundColor Gray -NoNewline
    Start-Sleep -Seconds 1
}

Write-Host "`r[脚本结束] 执行完毕, 正在退出...                          " -ForegroundColor Gray
