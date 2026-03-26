# ==========================================================
# ClientType: origin, wegame
# ==========================================================
param (
    [string]$CLIENT_TYPE = "origin"
)

# --- 1. 路径初始化 ---
$ConfigFilePath = Join-Path $PSScriptRoot "..\LOL_ROOT_PATH"
$LOL_ROOT_PATH  = (Get-Content -Path $ConfigFilePath -Raw -Encoding UTF8).Trim()

$ACE_PATH               = Join-Path $LOL_ROOT_PATH "Game\AntiCheatExpert\SGuard\x64\SGuard64.exe"
$LOL_CLIENT_ORIGIN_PATH = Join-Path $LOL_ROOT_PATH "Launcher\Client.exe"
$LOL_CLIENT_WEGAME_PATH = Join-Path $LOL_ROOT_PATH "WeGameLauncher\launcher.exe"
$LOL_RUNNER_PATH        = Join-Path $LOL_ROOT_PATH "LeagueClient\LeagueClient.exe"

# --- 2. 辅助函数与进程名提取 ---
function Get-ProcessName($path) {
    return [System.IO.Path]::GetFileNameWithoutExtension($path)
}

$ACE               = Get-ProcessName $ACE_PATH
$LOL_CLIENT_ORIGIN = Get-ProcessName $LOL_CLIENT_ORIGIN_PATH
$LOL_CLIENT_WEGAME = Get-ProcessName $LOL_CLIENT_WEGAME_PATH
$LOL_RUNNER        = Get-ProcessName $LOL_RUNNER_PATH

function Get-Current-LOL-Client-Info($type) {
    if ($type -eq "wegame") {
        return $LOL_CLIENT_WEGAME, $LOL_CLIENT_WEGAME_PATH
    }
    if ($type -eq "origin") {
        return $LOL_CLIENT_ORIGIN, $LOL_CLIENT_ORIGIN_PATH
    } else {
        Write-Host "[参数错误] 无效的客户端类型: '$type', 将默认使用 LOL原生 模式。" -ForegroundColor Yellow
        return $LOL_CLIENT_ORIGIN, $LOL_CLIENT_ORIGIN_PATH
    }
}

$LOL_CLIENT, $LOL_CLIENT_PATH = Get-Current-LOL-Client-Info $CLIENT_TYPE

# --- 3. 组件显示名称定义 ---
$NAME_ACE    = "反作弊组件 (ACE: $($ACE).exe)"
$NAME_CLIENT = if ($CLIENT_TYPE -eq "wegame") { "客户端 (WeGame: $($LOL_CLIENT_WEGAME).exe)" } else { "客户端 (Origin: $($LOL_CLIENT_ORIGIN).exe)" }
$NAME_RUNNER = "英雄联盟主程序 (Main: $($LOL_RUNNER).exe)"

function Log-State([string]$Tag, [string]$Msg, [ConsoleColor]$Color = "Gray") {
    Write-Host ("[{0}] {1}" -f $Tag, $Msg) -ForegroundColor $Color
}

# --- 4. 环境清理阶段 ---
while ($true) {
    if (Get-Process -Name $LOL_RUNNER -ErrorAction SilentlyContinue) {
        Log-State "环境检查" "检测到 $NAME_RUNNER 正在运行, 请先关闭游戏..." "Yellow"
        Start-Sleep -Seconds 2
        continue
    }

    if (Get-Process -Name $ACE -ErrorAction SilentlyContinue) {
        Log-State "进程等待" "正在等待 $NAME_ACE 完全退出..." "Yellow"
        Start-Sleep -Seconds 2
        continue
    }
    break
}

Log-State "状态就绪" "运行环境已清理, 准备执行启动流程。" "Green"

# --- 5. 启动逻辑循环 ---
while ($true) {
    # 检查并启动 ACE
    if (-not (Get-Process -Name $ACE -ErrorAction SilentlyContinue)) {
        Log-State "执行启动" "正在调起 $NAME_ACE..." "Cyan"
        Start-Process -FilePath $ACE_PATH
        Start-Sleep -Seconds 2
        continue
    }

    # 检查并启动 LOL 
    if (-not (Get-Process -Name $LOL_RUNNER -ErrorAction SilentlyContinue)) {
        if (-not (Get-Process -Name $LOL_CLIENT -ErrorAction SilentlyContinue)) {
            Log-State "执行启动" "正在通过 $CLIENT_TYPE 模式启动 $NAME_CLIENT..." "Cyan"
            Start-Process -FilePath $LOL_CLIENT_PATH
            Start-Sleep -Seconds 2
            continue
        }

        Log-State "正在引导" "已启动 $NAME_CLIENT, 正在等待用户登录并加载 $NAME_RUNNER..." "DarkGray"
        Start-Sleep -Seconds 2
        continue
    }

    Log-State "启动成功" "$NAME_RUNNER 与 $NAME_ACE 均已进入运行状态！" "Green"
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
