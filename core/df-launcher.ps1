# ==========================================================
# Delta Force Launcher
# ClientType: origin, steam
# ==========================================================
param (
    [string]$CLIENT_TYPE = "origin"
)

if ([string]::IsNullOrWhiteSpace($CLIENT_TYPE)) {
    $CLIENT_TYPE = "origin"
}
$CLIENT_TYPE = $CLIENT_TYPE.Trim().ToLowerInvariant()

function Log-State([string]$Tag, [string]$Msg, [ConsoleColor]$Color = "Gray") {
    Write-Host ("[{0}] {1}" -f $Tag, $Msg) -ForegroundColor $Color
}


# --- 1. 路径校验 ---

function Validate-Delta-Root-Path($path, [string]$ClientType = "origin") {
    if (-not (Test-Path $path)) { return $false }
    $RequiredDirs = "DeltaForce", "Engine"
    if ($ClientType -eq "origin") {
        $RequiredDirs += "TCLS"
    }

    foreach ($dir in $RequiredDirs) {
        if (-not (Test-Path (Join-Path $path $dir))) { return $false }
    }

    $runnerPath = Join-Path $path "DeltaForce\Binaries\Win64\DeltaForceClient-Win64-Shipping.exe"
    $acePath    = Join-Path $path "DeltaForce\Binaries\Win64\AntiCheatExpert\SGuard\x64\SGuard64.exe"
    return (Test-Path $runnerPath) -and (Test-Path $acePath)
}

function Validate-Delta-Launcher-Path($path) {
    if (-not (Test-Path $path)) { return $false }
    return ([System.IO.Path]::GetFileName($path) -ieq "delta_force_launcher.exe")
}

function Validate-Steam-Path($path) {
    if (-not (Test-Path $path)) { return $false }
    return ([System.IO.Path]::GetFileName($path) -ieq "steam.exe")
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

function Auto-Detect-Delta-Root-Path([string]$ClientType) {
    $cached = Get-Registry-Path "DeltaRootPath"
    if ($cached) {
        Log-State "读取缓存" "已从注册表读取路径: $cached" "DarkGray"
        if (Validate-Delta-Root-Path $cached $ClientType) {
            Log-State "命中缓存" "Delta Force 根目录已确认: $cached" "Green"
            return $cached
        }
        Log-State "缓存失效" "注册表路径已失效, 将重新扫描。" "Yellow"
    }

    Log-State "自动检测" "正在搜索 Delta Force 安装目录, 请稍候..." "Yellow"

    $drives = Get-SortedDrives
    foreach ($drive in $drives) {
        $results = & where.exe /R $drive DeltaForceClient-Win64-Shipping.exe 2>$null
        foreach ($result in $results) {
            if (-not $result) { continue }
            # DeltaForceClient-Win64-Shipping.exe 路径:
            # <root>\DeltaForce\Binaries\Win64\DeltaForceClient-Win64-Shipping.exe
            $rootPath = Split-Path (Split-Path (Split-Path (Split-Path $result.Trim() -Parent) -Parent) -Parent) -Parent
            if (Validate-Delta-Root-Path $rootPath $ClientType) {
                Log-State "检测成功" "已找到 Delta Force 根目录: $rootPath" "Green"
                Save-Registry-Path "DeltaRootPath" $rootPath
                Log-State "写入缓存" "路径已写入注册表, 下次启动将优先读取。" "DarkGray"
                return $rootPath
            }
        }
    }

    Log-State "检测失败" "未能自动找到 Delta Force 安装目录。" "Red"
    if ($ClientType -eq "origin") {
        Write-Host "  请确认游戏已完整安装, 且目录包含 DeltaForce、Engine、TCLS 子目录。" -ForegroundColor Cyan
    } else {
        Write-Host "  请确认 Steam 版 Delta Force 已完整安装, 且目录包含 DeltaForce、Engine 子目录。" -ForegroundColor Cyan
    }
    exit 1
}

function Auto-Detect-Delta-Launcher-Path() {
    $cached = Get-Registry-Path "DeltaLauncherPath"
    if ($cached) {
        Log-State "读取缓存" "已从注册表读取路径: $cached" "DarkGray"
        if (Validate-Delta-Launcher-Path $cached) {
            Log-State "命中缓存" "Delta Force 启动器路径已确认: $cached" "Green"
            return $cached
        }
        Log-State "缓存失效" "注册表路径已失效, 将重新扫描。" "Yellow"
    }

    Log-State "自动检测" "正在搜索 Delta Force 启动器, 请稍候..." "Yellow"

    $drives = Get-SortedDrives
    foreach ($drive in $drives) {
        $results = & where.exe /R $drive delta_force_launcher.exe 2>$null
        foreach ($result in $results) {
            if (-not $result) { continue }
            $path = $result.Trim()
            if (Validate-Delta-Launcher-Path $path) {
                Log-State "检测成功" "已找到 Delta Force 启动器: $path" "Green"
                Save-Registry-Path "DeltaLauncherPath" $path
                Log-State "写入缓存" "路径已写入注册表, 下次启动将优先读取。" "DarkGray"
                return $path
            }
        }
    }

    Log-State "检测失败" "未能自动找到 Delta Force 启动器。" "Red"
    Write-Host "  提示: Delta Force 官方启动器需单独安装, 脚本不会自动下载。" -ForegroundColor Yellow
    Write-Host "  官网: https://df.qq.com/ 点击官网下载并安装到任意位置后, 重新运行脚本即可。" -ForegroundColor Cyan
    exit 1
}

function Get-Steam-Candidate-Paths() {
    $candidates = New-Object System.Collections.Generic.List[string]

    try {
        $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($steamProcess -and $steamProcess.Path) {
            $candidates.Add($steamProcess.Path)
        }
    } catch {
    }

    $registryKeys = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam"
    )

    foreach ($key in $registryKeys) {
        try {
            $props = Get-ItemProperty -Path $key -ErrorAction Stop
            foreach ($name in @("SteamExe", "InstallPath", "SteamPath")) {
                $value = $props.$name
                if ([string]::IsNullOrWhiteSpace($value)) { continue }

                if ([System.IO.Path]::GetFileName($value) -ieq "steam.exe") {
                    $candidates.Add($value)
                } else {
                    $candidates.Add((Join-Path $value "steam.exe"))
                }
            }
        } catch {
            continue
        }
    }

    if ($env:ProgramFiles) {
        $candidates.Add((Join-Path $env:ProgramFiles "Steam\steam.exe"))
    }

    $programFilesX86 = ${env:ProgramFiles(x86)}
    if ($programFilesX86) {
        $candidates.Add((Join-Path $programFilesX86 "Steam\steam.exe"))
    }

    return ($candidates | Select-Object -Unique)
}

function Auto-Detect-Steam-Path() {
    $cached = Get-Registry-Path "SteamPath"
    if ($cached) {
        Log-State "读取缓存" "已从注册表读取路径: $cached" "DarkGray"
        if (Validate-Steam-Path $cached) {
            Log-State "命中缓存" "Steam 客户端路径已确认: $cached" "Green"
            return $cached
        }
        Log-State "缓存失效" "注册表路径已失效, 将重新扫描。" "Yellow"
    }

    Log-State "自动检测" "正在搜索 Steam 客户端, 请稍候..." "Yellow"

    foreach ($candidate in Get-Steam-Candidate-Paths) {
        if (Validate-Steam-Path $candidate) {
            Log-State "检测成功" "已找到 Steam 客户端: $candidate" "Green"
            Save-Registry-Path "SteamPath" $candidate
            Log-State "写入缓存" "路径已写入注册表, 下次启动将优先读取。" "DarkGray"
            return $candidate
        }
    }

    $drives = Get-SortedDrives
    foreach ($drive in $drives) {
        $results = & where.exe /R $drive steam.exe 2>$null
        foreach ($result in $results) {
            if (-not $result) { continue }
            $path = $result.Trim()
            if (Validate-Steam-Path $path) {
                Log-State "检测成功" "已找到 Steam 客户端: $path" "Green"
                Save-Registry-Path "SteamPath" $path
                Log-State "写入缓存" "路径已写入注册表, 下次启动将优先读取。" "DarkGray"
                return $path
            }
        }
    }

    Log-State "检测失败" "未能自动找到 Steam 客户端。" "Red"
    Write-Host "  请确认 Steam 已安装, 或先手动启动 Steam 后重新运行脚本。" -ForegroundColor Cyan
    exit 1
}

if (($CLIENT_TYPE -ne "origin") -and ($CLIENT_TYPE -ne "steam")) {
    Log-State "参数错误" "无效的客户端类型: '$CLIENT_TYPE', 将默认使用 Origin 模式。" "Yellow"
    $CLIENT_TYPE = "origin"
}


# --- 3. 路径初始化 ---
$DELTA_ROOT_PATH = Auto-Detect-Delta-Root-Path $CLIENT_TYPE

$DELTA_ACE_PATH        = Join-Path $DELTA_ROOT_PATH "DeltaForce\Binaries\Win64\AntiCheatExpert\SGuard\x64\SGuard64.exe"
$DELTA_ACE_DIR         = Split-Path $DELTA_ACE_PATH -Parent
$DELTA_ACE_PROCESS     = Get-ProcessName $DELTA_ACE_PATH
$DELTA_ACE_NAME        = "Delta Force 反作弊组件 (${DELTA_ACE_PROCESS}.exe)"

$DELTA_RUNNER_PATH     = Join-Path $DELTA_ROOT_PATH "DeltaForce\Binaries\Win64\DeltaForceClient-Win64-Shipping.exe"
$DELTA_RUNNER_PROCESS  = Get-ProcessName $DELTA_RUNNER_PATH
$DELTA_RUNNER_NAME     = "Delta Force 主程序 (${DELTA_RUNNER_PROCESS}.exe)"

if ($CLIENT_TYPE -eq "steam") {
    $DELTA_LAUNCHER_PATH = Auto-Detect-Steam-Path
    $DELTA_LAUNCHER_NAME_PREFIX = "Steam 客户端"
} else {
    $DELTA_LAUNCHER_PATH = Auto-Detect-Delta-Launcher-Path
    $DELTA_LAUNCHER_NAME_PREFIX = "Delta Force 启动器"
}

$DELTA_LAUNCHER_DIR     = Split-Path $DELTA_LAUNCHER_PATH -Parent
$DELTA_LAUNCHER_PROCESS = Get-ProcessName $DELTA_LAUNCHER_PATH
$DELTA_LAUNCHER_NAME    = "$DELTA_LAUNCHER_NAME_PREFIX (${DELTA_LAUNCHER_PROCESS}.exe)"


# --- 4. 环境清理阶段 ---
while ($true) {
    if (Get-Process -Name $DELTA_RUNNER_PROCESS -ErrorAction SilentlyContinue) {
        Log-State "环境检查" "检测到 $DELTA_RUNNER_NAME 正在运行, 请先关闭游戏..." "Yellow"
        Start-Sleep -Seconds 2
        continue
    }

    if (Get-Process -Name $DELTA_ACE_PROCESS -ErrorAction SilentlyContinue) {
        Log-State "进程等待" "正在等待 $DELTA_ACE_NAME 完全退出..." "Yellow"
        Start-Sleep -Seconds 2
        continue
    }
    break
}

Log-State "状态就绪" "运行环境已清理, 准备执行启动流程。" "Green"

# --- 5. 启动逻辑循环 ---
while ($true) {
    if (-not (Get-Process -Name $DELTA_ACE_PROCESS -ErrorAction SilentlyContinue)) {
        Log-State "执行启动" "正在调起 $DELTA_ACE_NAME..." "Cyan"
        Start-Process -FilePath $DELTA_ACE_PATH -WorkingDirectory $DELTA_ACE_DIR
        Start-Sleep -Seconds 2
        continue
    }

    if (-not (Get-Process -Name $DELTA_RUNNER_PROCESS -ErrorAction SilentlyContinue)) {
        if (-not (Get-Process -Name $DELTA_LAUNCHER_PROCESS -ErrorAction SilentlyContinue)) {
            Log-State "执行启动" "正在启动 $DELTA_LAUNCHER_NAME..." "Cyan"
            Start-Process -FilePath $DELTA_LAUNCHER_PATH -WorkingDirectory $DELTA_LAUNCHER_DIR
            Start-Sleep -Seconds 2
            continue
        }

        if ($CLIENT_TYPE -eq "steam") {
            Log-State "正在引导" "已启动 $DELTA_LAUNCHER_NAME, 请在 Steam 中手动启动 Delta Force, 正在等待加载 $DELTA_RUNNER_NAME..." "DarkGray"
        } else {
            Log-State "正在引导" "已启动 $DELTA_LAUNCHER_NAME, 正在等待用户登录并加载 $DELTA_RUNNER_NAME..." "DarkGray"
        }
        Start-Sleep -Seconds 2
        continue
    }

    Log-State "启动成功" "$DELTA_ACE_NAME 与 $DELTA_RUNNER_NAME 均已进入运行状态！" "Green"
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
