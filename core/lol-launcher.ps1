# ==========================================================
# ClientType: origin, akari, wegame
# ==========================================================
param (
    [string]$CLIENT_TYPE = "origin"
)


function Log-State([string]$Tag, [string]$Msg, [ConsoleColor]$Color = "Gray") {
    Write-Host ("[{0}] {1}" -f $Tag, $Msg) -ForegroundColor $Color
}

function Show-WeGame-Mode-Notice() {
    Write-Host ""
    Log-State "失效警告" "WeGame 模式仅保留兼容入口, 当前不推荐用于减少掉帧。" "Yellow"
    Log-State "失效警告" "近期 WeGame 更新后, 疑似会结束脚本提前启动的 SGuard64.exe, 再重新拉起 SGuard64.exe + SGuardSvc64.exe。" "Yellow"
    Log-State "失效警告" "这种情况下本脚本的 ACE 启动顺序优化可能失效, 建议优先使用 Origin 或 Akari 模式。" "Yellow"
    Write-Host ""
}

if ($CLIENT_TYPE -eq "wegame") {
    Show-WeGame-Mode-Notice
}


# --- 1. 路径校验 ---


function Validate-LOL-Root-Path($path) {
    if (-not (Test-Path $path)) { return $false }
    # 校验必要子目录完整性
    $RequiredDirs = "Game", "Launcher", "LeagueClient"
    foreach ($dir in $RequiredDirs) {
        if (-not (Test-Path (Join-Path $path $dir))) { return $false }
    }
    return $true
}

function Validate-Akari-Path($path) {
    if (-not (Test-Path $path)) { return $false }
    return $true
}


# --- 注册表缓存 ---
$REG_KEY = "HKCU:\Software\iWonder\GameLauncher"

function Get-Registry-Path([string]$ValueName) {
    try {
        $val = Get-ItemProperty -Path $REG_KEY -Name $ValueName -ErrorAction Stop
        return $val.$ValueName
    } catch {
        return $null
    }
}

function Save-Registry-Path([string]$ValueName, [string]$Path) {
    if (-not (Test-Path $REG_KEY)) {
        New-Item -Path $REG_KEY -Force | Out-Null
    }
    Set-ItemProperty -Path $REG_KEY -Name $ValueName -Value $Path
}


# --- 2. 辅助函数与进程名提取 ---
function Get-ProcessName($path) {
    return [System.IO.Path]::GetFileNameWithoutExtension($path)
}


function Get-SortedDrives() {
    $allDrives = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\'}).Root
    $priority  = @('D:\', 'C:\', 'E:\', 'F:\')
    $sorted    = $priority | Where-Object { $allDrives -contains $_ }
    $sorted   += $allDrives | Where-Object { $priority -notcontains $_ } | Sort-Object
    return $sorted
}

function Auto-Detect-LOL-Root-Path() {
    $cached = Get-Registry-Path "LOLRootPath"
    if ($cached) {
        Log-State "读取缓存" "已从注册表读取路径: $cached" "DarkGray"
        if (Validate-LOL-Root-Path $cached) {
            Log-State "命中缓存" "英雄联盟根目录已确认: $cached" "Green"
            return $cached
        }
        Log-State "缓存失效" "注册表路径已失效, 将重新扫描。" "Yellow"
    }

    Log-State "自动检测" "正在搜索英雄联盟安装目录, 请稍候..." "Yellow"

    $drives = Get-SortedDrives
    foreach ($drive in $drives) {
        $results = & where.exe /R $drive LeagueClient.exe 2>$null
        foreach ($result in $results) {
            if (-not $result) { continue }
            # LeagueClient.exe 路径: <root>\LeagueClient\LeagueClient.exe，向上两级即为根目录
            $rootPath = Split-Path (Split-Path $result.Trim() -Parent) -Parent
            if (Validate-LOL-Root-Path $rootPath) {
                Log-State "检测成功" "已找到英雄联盟根目录: $rootPath" "Green"
                Save-Registry-Path "LOLRootPath" $rootPath
                Log-State "写入缓存" "路径已写入注册表, 下次启动将优先读取。" "DarkGray"
                return $rootPath
            }
        }
    }

    Log-State "检测失败" "未能自动找到英雄联盟安装目录。" "Red"
    Write-Host "  请确认游戏已完整安装, 且目录包含 Game、Launcher、LeagueClient 子目录。" -ForegroundColor Cyan
    exit 1
}

function Auto-Detect-Akari-Path() {
    $cached = Get-Registry-Path "AkariPath"
    if ($cached) {
        Log-State "读取缓存" "已从注册表读取路径: $cached" "DarkGray"
        if (Validate-Akari-Path $cached) {
            Log-State "命中缓存" "Akari 客户端路径已确认: $cached" "Green"
            return $cached
        }
        Log-State "缓存失效" "注册表路径已失效, 将重新扫描。" "Yellow"
    }

    Log-State "自动检测" "正在搜索 Akari 客户端, 请稍候..." "Yellow"

    $drives = Get-SortedDrives
    foreach ($drive in $drives) {
        $results = & where.exe /R $drive LeagueAkari.exe 2>$null
        foreach ($result in $results) {
            if (-not $result) { continue }
            $path = $result.Trim()
            if (Validate-Akari-Path $path) {
                Log-State "检测成功" "已找到 Akari 客户端: $path" "Green"
                Save-Registry-Path "AkariPath" $path
                Log-State "写入缓存" "路径已写入注册表, 下次启动将优先读取。" "DarkGray"
                return $path
            }
        }
    }

    Log-State "检测失败" "未能自动找到 Akari 客户端。" "Red"
    Write-Host "  如尚未安装 Akari 助手, 请先前往官方项目页下载并安装。" -ForegroundColor Yellow
    Write-Host "  官网: https://github.com/LeagueAkari/LeagueAkari/" -ForegroundColor Cyan
    exit 1
}

# 逻辑触发
# LOL_ROOT_PATH 自动检测
$LOL_ROOT_PATH = Auto-Detect-LOL-Root-Path

$ACE_PATH               = Join-Path $LOL_ROOT_PATH "Game\AntiCheatExpert\SGuard\x64\SGuard64.exe"
$ACE_PROCESS            = Get-ProcessName $ACE_PATH
$ACE_NAME               = "反作弊组件 (${ACE_PROCESS}.exe)"

$LOL_RUNNER_PATH        = Join-Path $LOL_ROOT_PATH "LeagueClient\LeagueClient.exe"
$LOL_RUNNER_PROCESS     = Get-ProcessName $LOL_RUNNER_PATH
$LOL_RUNNER_NAME        = "英雄联盟主程序 (${LOL_RUNNER_PROCESS}.exe)"


# Akari路径 自动检测（仅在选择 Akari 模式时触发）
if ($CLIENT_TYPE -eq "akari") {
    $AKARI_PATH = Auto-Detect-Akari-Path

    $LOL_CLIENT_PATH    = $AKARI_PATH
    $LOL_CLIENT_PROCESS = Get-ProcessName $LOL_CLIENT_PATH
    $LOL_CLIENT_NAME    = "Akari客户端 (${LOL_CLIENT_PROCESS}.exe)"

    # akari, 无法自动启动lol. 
    $LOL_CLIENT_ORIGIN_PATH    = Join-Path $LOL_ROOT_PATH "Launcher\Client.exe"
    $LOL_CLIENT_ORIGIN_PROCESS = Get-ProcessName $LOL_CLIENT_ORIGIN_PATH
    $LOL_CLIENT_ORIGIN_NAME    = "Origin客户端 (${LOL_CLIENT_ORIGIN_PROCESS}.exe)"

} elseif ($CLIENT_TYPE -eq "wegame") {
    $LOL_CLIENT_PATH    = Join-Path $LOL_ROOT_PATH "WeGameLauncher\launcher.exe"
    $LOL_CLIENT_PROCESS = Get-ProcessName $LOL_CLIENT_PATH
    $LOL_CLIENT_NAME    = "WeGame客户端 (${LOL_CLIENT_PROCESS}.exe)"

} elseif ($CLIENT_TYPE -eq "origin") {
    $LOL_CLIENT_PATH    = Join-Path $LOL_ROOT_PATH "Launcher\Client.exe"
    $LOL_CLIENT_PROCESS = Get-ProcessName $LOL_CLIENT_PATH
    $LOL_CLIENT_NAME    = "Origin客户端 (${LOL_CLIENT_PROCESS}.exe)"

} else {
    Log-State "参数错误" "无效的客户端类型: '$CLIENT_TYPE', 将默认使用 Origin 模式。" "Yellow"
    $LOL_CLIENT_PATH    = Join-Path $LOL_ROOT_PATH "Launcher\Client.exe"
    $LOL_CLIENT_PROCESS = Get-ProcessName $LOL_CLIENT_PATH
    $LOL_CLIENT_NAME    = "Origin客户端 (${LOL_CLIENT_PROCESS}.exe)"
}






# --- 4. 环境清理阶段 ---
while ($true) {
    if (Get-Process -Name $LOL_RUNNER_PROCESS -ErrorAction SilentlyContinue) {
        Log-State "环境检查" "检测到 $LOL_RUNNER_NAME 正在运行, 请先关闭游戏..." "Yellow"
        Start-Sleep -Seconds 2
        continue
    }

    if (Get-Process -Name $ACE_PROCESS -ErrorAction SilentlyContinue) {
        Log-State "进程等待" "正在等待 $ACE_NAME 完全退出..." "Yellow"
        Start-Sleep -Seconds 2
        continue
    }
    break
}

Log-State "状态就绪" "运行环境已清理, 准备执行启动流程。" "Green"

# --- 5. 启动逻辑循环 ---
while ($true) {
    # 检查并启动 ACE
    if (-not (Get-Process -Name $ACE_PROCESS -ErrorAction SilentlyContinue)) {
        Log-State "执行启动" "正在调起 $ACE_NAME..." "Cyan"
        Start-Process -FilePath $ACE_PATH
        Start-Sleep -Seconds 2
        continue
    }

    # 检查并启动 LOL 
    if (-not (Get-Process -Name $LOL_RUNNER_PROCESS -ErrorAction SilentlyContinue)) {
        if ($CLIENT_TYPE -eq "akari") {
            if (-not (Get-Process -Name $LOL_CLIENT_PROCESS -ErrorAction SilentlyContinue)) {
                Log-State "执行启动" "正在通过 $CLIENT_TYPE 模式启动 $LOL_CLIENT_NAME..." "Cyan"
                Start-Process -FilePath $LOL_CLIENT_PATH -RedirectStandardOutput "$env:TEMP\stdout.log" -RedirectStandardError "$env:TEMP\stderr.log"
                Start-Sleep -Seconds 2
                continue
            }
            elseif (-not (Get-Process -Name $LOL_CLIENT_ORIGIN_PROCESS -ErrorAction SilentlyContinue)) {
                Log-State "执行启动" "检测到 Akari 模式, 正在调起 $LOL_CLIENT_ORIGIN_NAME..." "Cyan"
                Start-Process -FilePath $LOL_CLIENT_ORIGIN_PATH
                Start-Sleep -Seconds 2
                continue
            }
        }
        elseif (-not (Get-Process -Name $LOL_CLIENT_PROCESS -ErrorAction SilentlyContinue)) {
            Log-State "执行启动" "正在通过 $CLIENT_TYPE 模式启动 $LOL_CLIENT_NAME..." "Cyan"
            Start-Process -FilePath $LOL_CLIENT_PATH 
            Start-Sleep -Seconds 2
            continue
        }

        Log-State "正在引导" "已启动 $LOL_CLIENT_NAME, 正在等待用户登录并加载 $LOL_RUNNER_NAME..." "DarkGray"
        Start-Sleep -Seconds 2
        continue
    }

    Log-State "启动成功" "$ACE_NAME 与 $LOL_RUNNER_NAME 均已进入运行状态！" "Green"
    break
}

# --- 6. 倒计时自动退出 ---
Write-Host "" 
for ($i = 3; $i -gt 0; $i--) {
    Write-Host ("`r[脚本结束] 执行完毕, 将在 {0} 秒后自动退出..." -f $i) -ForegroundColor Gray -NoNewline
    Start-Sleep -Seconds 1
}

Write-Host "`r[脚本结束] 执行完毕, 正在退出...                          " -ForegroundColor Gray
exit
