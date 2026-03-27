# ==========================================================
# ClientType: origin, akari, wegame
# ==========================================================
param (
    [string]$CLIENT_TYPE = "origin"
)


function Log-State([string]$Tag, [string]$Msg, [ConsoleColor]$Color = "Gray") {
    Write-Host ("[{0}] {1}" -f $Tag, $Msg) -ForegroundColor $Color
}


# --- 1. 路径初始化与校验 ---
$ConfigPath = Join-Path $PSScriptRoot "..\config.json"


# 获取单层配置值
function Get-ConfigValue($key) {
    
    if (-not (Test-Path $ConfigPath)) { return $null }
    
    $data = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    return $data.$key
}

# 设置单层配置值
function Set-ConfigValue($key, $value) {

    # 读取现有数据或初始化新对象
    if (Test-Path $ConfigPath) {
        $data = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    } else {
        $data = New-Object PSCustomObject
    }

    # 直接赋值（如果 key 包含点号，PowerShell 会将其视为整体字段名）
    if ($data.psobject.Properties[$key]) {
        $data.$key = $value
    } else {
        $data | Add-Member -MemberType NoteProperty -Name $key -Value $value
    }

    # 写回文件
    $data | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8
}


function Validate-LOL-Root-Path($path) {
    if (-not (Test-Path $path)) { return $false }
    # 校验必要子目录完整性
    $RequiredDirs = "Cross", "Game", "Launcher", "LeagueClient"
    foreach ($dir in $RequiredDirs) {
        if (-not (Test-Path (Join-Path $path $dir))) { return $false }
    }
    # 路径合法性检查：不能包含中文
    if ($path -match "[\u4e00-\u9fa5]") { return $false }
    return $true
}

function Validate-Akari-Path($path) {
    if (-not (Test-Path $path)) { return $false }

    # 路径合法性检查：不能包含中文
    if ($path -match "[\u4e00-\u9fa5]") { return $false }
    return $true
}


# --- 2. 辅助函数与进程名提取 ---
function Get-ProcessName($path) {
    return [System.IO.Path]::GetFileNameWithoutExtension($path)
}


function Set-Config-from-LOL-Root-Path($path) {
    $ACE_PATH               = Join-Path $path "Game\AntiCheatExpert\SGuard\x64\SGuard64.exe"
    $LOL_CLIENT_ORIGIN_PATH = Join-Path $path "Launcher\Client.exe"
    $LOL_CLIENT_WEGAME_PATH = Join-Path $path "WeGameLauncher\launcher.exe"
    $LOL_RUNNER_PATH        = Join-Path $path "LeagueClient\LeagueClient.exe"

    $ACE_PROCESS               = Get-ProcessName $ACE_PATH
    $LOL_CLIENT_ORIGIN_PROCESS = Get-ProcessName $LOL_CLIENT_ORIGIN_PATH
    $LOL_CLIENT_WEGAME_PROCESS = Get-ProcessName $LOL_CLIENT_WEGAME_PATH
    $LOL_RUNNER_PROCESS        = Get-ProcessName $LOL_RUNNER_PATH


    Set-ConfigValue -key "lol_root_path" -value $path

    Set-ConfigValue -key "ace.path" -value $ACE_PATH
    Set-ConfigValue -key "ace.process" -value $ACE_PROCESS
    Set-ConfigValue -key "ace.name" -value "反作弊组件 (${ACE_PROCESS}.exe)"

    Set-ConfigValue -key "lol_client.origin.path" -value $LOL_CLIENT_ORIGIN_PATH
    Set-ConfigValue -key "lol_client.origin.process" -value $LOL_CLIENT_ORIGIN_PROCESS
    Set-ConfigValue -key "lol_client.origin.name" -value "Origin客户端 (${LOL_CLIENT_ORIGIN_PROCESS}.exe)"

    Set-ConfigValue -key "lol_client.wegame.path" -value $LOL_CLIENT_WEGAME_PATH
    Set-ConfigValue -key "lol_client.wegame.process" -value $LOL_CLIENT_WEGAME_PROCESS
    Set-ConfigValue -key "lol_client.wegame.name" -value "WeGame客户端 (${LOL_CLIENT_WEGAME_PROCESS}.exe)"

    Set-ConfigValue -key "lol_runner.path" -value $LOL_RUNNER_PATH
    Set-ConfigValue -key "lol_runner.process" -value $LOL_RUNNER_PROCESS
    Set-ConfigValue -key "lol_runner.name" -value "英雄联盟主程序 (${LOL_RUNNER_PROCESS}.exe)"
}


function Set-Config-from-Akari-Path($path) {
    $AKARI_PROCESS = Get-ProcessName $path

    Set-ConfigValue -key "akari.path" -value $path
    Set-ConfigValue -key "akari.process" -value $AKARI_PROCESS
    Set-ConfigValue -key "akari.name" -value "Akari客户端 (${AKARI_PROCESS}.exe)"
}


function Prompt-For-LOL-Root-Path() {
    while ($true) {
        Write-Host "`n[配置引导] 请输入英雄联盟(LOL)根目录路径：" -ForegroundColor Yellow
        Write-Host "  示例: D:\Tencent\WeGameApps\League of Legends" -ForegroundColor Gray
        Write-Host "  要求: 路径须 [完整] 且路径中 [不可包含中文], 请修改至符合要求后, 再进行后续操作" -ForegroundColor Cyan
        
        $NewPath = (Read-Host ">> 路径").Trim()
        
        if (Validate-LOL-Root-Path $NewPath) {
            Set-ConfigValue -key "LOL_ROOT_PATH" -value $NewPath
            Write-Host "[配置成功] 英雄联盟(LOL)根目录相关路径 已写入配置文件。" -ForegroundColor Green
            return $NewPath
        } else {
            Write-Host "[校验失败] 路径无效：请检查目录完整性或是否存在中文。" -ForegroundColor Red
        }
    }
}

function Prompt-For-Akari-Path() {
    while ($true) {
        Write-Host "`n[配置引导] 请输入 Akari 客户端路径：" -ForegroundColor Yellow
        Write-Host "  示例: D:\League.Akari-1.4.3-win\LeagueAkari.exe" -ForegroundColor Gray
        Write-Host "  要求: 路径须 [完整] 且路径中 [不可包含中文], 请修改至符合要求后, 再进行后续操作" -ForegroundColor Cyan
        
        $NewPath = (Read-Host ">> 路径").Trim()
        
        if (Test-Path $NewPath) {
            Set-ConfigValue -key "AKARI_PATH" -value $NewPath
            Write-Host "[配置成功] Akari客户端相关路径 已写入配置文件。" -ForegroundColor Green
            return $NewPath
        } else {
            Write-Host "[校验失败] 路径无效：请检查目录完整性或是否存在中文。" -ForegroundColor Red
        }
    }
}

# 逻辑触发
# LOL_ROOT_PATH 校验与配置
$LOL_ROOT_PATH = Get-ConfigValue -key "LOL_ROOT_PATH"
if (-not $LOL_ROOT_PATH -or -not (Validate-LOL-Root-Path $LOL_ROOT_PATH)) {
    if ($LOL_ROOT_PATH) {
        Write-Host "[配置错误] 检测到已保存的路径无效或包含非法字符。" -ForegroundColor Red
    } else {
        Write-Host "[初始设置] 未检测到 英雄联盟(LOL)根目录相关路径 配置文件。" -ForegroundColor Yellow
    }
    $LOL_ROOT_PATH = Prompt-For-LOL-Root-Path
}

$ACE_PATH               = Join-Path $LOL_ROOT_PATH "Game\AntiCheatExpert\SGuard\x64\SGuard64.exe"
$ACE_PROCESS            = Get-ProcessName $ACE_PATH
$ACE_NAME               = "反作弊组件 (${ACE_PROCESS}.exe)"

$LOL_RUNNER_PATH        = Join-Path $LOL_ROOT_PATH "LeagueClient\LeagueClient.exe"
$LOL_RUNNER_PROCESS     = Get-ProcessName $LOL_RUNNER_PATH
$LOL_RUNNER_NAME        = "英雄联盟主程序 (${LOL_RUNNER_PROCESS}.exe)"


# Akari路径 校验与配置（仅在选择 Akari 模式时触发）
if ($CLIENT_TYPE -eq "akari") {
    $AKARI_PATH = Get-ConfigValue -key "AKARI_PATH"
    if (-not $AKARI_PATH  -or -not (Validate-Akari-Path $AKARI_PATH)) {

        if ($AKARI_PATH) {
            Write-Host "[配置错误] 检测到已保存的路径无效或包含非法字符。" -ForegroundColor Red
        } else {
            Write-Host "[初始设置] 未检测到 Akari客户端相关路径 配置文件。" -ForegroundColor Yellow
        }
        $AKARI_PATH = Prompt-For-Akari-Path
    }

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
    Write-Host "[参数错误] 无效的客户端类型: '$CLIENT_TYPE', 将默认使用 Origin 模式。" -ForegroundColor Yellow
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
