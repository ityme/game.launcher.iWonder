# 🚀 游戏优化启动器 · 告别团战掉帧

专为国服lol《英雄联盟》与df《三角洲行动》设计的启动优化工具。

通过抢先调起 **ACE 游戏内置版**反作弊组件，取代扫描频繁、资源占用高的系统默认版，从底层减少游戏过程中的掉帧与卡顿。

---

## 🔑 核心原理：为什么能防掉帧？

国服环境下通常并存两个版本的 **AntiCheatExpert (ACE)**：

| 版本 | 位置 | 特点 |
| :--- | :--- | :--- |
| **ACE 1（系统默认版）** | `C:\Program Files\...` | 磁盘扫描频繁，团战时 CPU 占用飙升，是掉帧的主因 |
| **ACE 2（游戏内置版）** | `游戏目录\...\AntiCheatExpert\...` | 性能开销更低，运行更稳定 |

**工具逻辑**：ACE 具有"同时只能运行一个实例"的特性。脚本抢先拉起目标游戏目录内置的 **ACE 2** 并持续保活，迫使游戏绑定更流畅的内置版本，从而显著提升 FPS 稳定性。

---

## 🎮 当前支持游戏

| 游戏 | 简称 | 支持入口 |
| :--- | :---: | :--- |
| **英雄联盟** | LOL | 官方原生客户端 / Akari / WeGame（保留兼容，不推荐） |
| **三角洲行动** | DF | 官方启动器 / Steam |

---

## 📂 项目目录结构

```text
game.launcher.iWonder/
├── 创建桌面图标.bat          # 🧷 创建桌面与开始菜单快捷方式
├── lol-launcher-by-origin.bat  # 🚀 LOL：官方原生客户端模式
├── lol-launcher-by-wegame.bat  # 🚀 LOL：WeGame 客户端模式（不推荐）
├── lol-launcher-by-akari.bat   # 🚀 LOL：Akari 客户端模式
├── df-launcher-by-origin.bat   # 🚀 DF：官方启动器模式
├── df-launcher-by-steam.bat    # 🚀 DF：Steam 客户端模式
├── README.md                   # 📄 本说明文档
├── assets/
│   └── icon/
│       ├── lol.ico             # 🎨 LOL 快捷方式图标
│       └── df.ico              # 🎨 DF 快捷方式图标
└── core/
    ├── create-shortcuts.ps1    # 🧷 快捷方式生成脚本
    ├── lol-launcher.ps1        # ✨ LOL 核心调度引擎
    └── df-launcher.ps1         # ✨ DF 核心调度引擎
```

---

## 🛠️ 第一步：下载

- [点击此处前往最新版本下载页](https://github.com/ityme/game.launcher.iWonder/releases/latest)，下载后解压到任意目录。

---

## 🧷 第二步：创建桌面图标

解压后，建议先双击运行：

```text
创建桌面图标.bat
```

脚本会自动创建以下快捷方式：

| 位置 | 快捷方式 |
| :--- | :--- |
| **桌面** | `lol-origin` / `lol-akari` / `df-origin` / `df-steam` |
| **开始菜单** | `game.launcher.iWonder\lol-origin` / `game.launcher.iWonder\lol-akari` / `game.launcher.iWonder\df-origin` / `game.launcher.iWonder\df-steam` |

| 快捷方式 | 实际启动模式 |
| :--- | :--- |
| `lol-origin` | LOL：官方原生客户端模式 |
| `lol-akari` | LOL：Akari 客户端模式 |
| `df-origin` | DF：官方启动器模式 |
| `df-steam` | DF：Steam 客户端模式 |

> 📌 **后续用法**：创建完成后，日常启动游戏只需要双击桌面图标，或按 `Win` 键搜索 `lol-origin`、`lol-akari`、`df-origin`、`df-steam`。

> 🔁 **路径说明**：快捷方式会指向当前项目目录。若之后移动了整个项目文件夹，请重新双击 `创建桌面图标.bat`，快捷方式会自动刷新到新路径。

> ⚠️ **WeGame 模式说明**：WeGame 模式不推荐，因此不会创建对应快捷方式。如确实需要使用，可在项目目录中手动双击 `lol-launcher-by-wegame.bat`。

---

## 🎮 第三步：选择启动方式

如果不想创建快捷方式，也可以根据你要玩的游戏与登录习惯选择对应入口，**直接双击运行**：

| 方案 | 启动文件 | 适用场景 |
| :---: | :--- | :--- |
| **A** | `lol-launcher-by-origin.bat` | LOL：直接弹出英雄联盟登录框，不经过 WeGame |
| **B** | `lol-launcher-by-wegame.bat` | LOL：保留给依赖 WeGame 的用户使用，但当前不推荐 |
| **C** | `lol-launcher-by-akari.bat` | LOL：使用 Akari 客户端，追求更轻量的启动体验 |
| **D** | `df-launcher-by-origin.bat` | DF：通过三角洲行动官方启动器进入游戏 |
| **E** | `df-launcher-by-steam.bat` | DF：启动 Steam，随后由用户在 Steam 中手动启动三角洲行动 |

> ⚠️ **WeGame 模式说明**：近期 WeGame 更新后，疑似会结束脚本提前启动的 `SGuard64.exe`，随后由 WeGame 重新拉起 `SGuard64.exe` 与 `SGuardSvc64.exe`。这会绕过本脚本对 ACE 启动顺序的优化，导致减少掉帧的效果失效。因此 WeGame 入口仍然提供，但建议优先使用 Origin 或 Akari 模式。

> 📌 **Steam 模式说明**：DF Steam 模式会先启动游戏内置 ACE，再启动 Steam 客户端；Steam 打开后，需要你在 Steam 中手动启动三角洲行动。

---

## ⏱️ 第四步：启动流程说明

双击运行后，脚本将**自动完成所有操作**，关注控制台窗口的输出提示：

1. **[自动检测]** — 脚本自动扫描全盘，找到对应游戏安装目录（LOL 使用 Akari 模式时也会检测 Akari 客户端；DF 会根据模式额外检测官方启动器或 Steam 客户端）。无需任何手动配置。
2. **[环境检查]** — 若出现黄色警告，说明存在残留的游戏或 ACE 进程，请先手动关闭后重试。
3. **[执行启动]** — 脚本自动拉起游戏内置的 ACE 2 反作弊组件。
4. **[正在引导]** — 出现此提示后，立即在对应游戏登录器中完成登录操作（登录账号 → 选择区服/模式 → 进入游戏）。
5. **[启动成功]** — 进入游戏大厅后，脚本显示绿色提示并开始 3 秒倒计时。
6. **[自动退出]** — 倒计时结束，窗口自动关闭，脚本完全释放资源。尽情享受游戏吧！

---

## ⚠️ 常见问题 FAQ

| 问题 | 解决方案 |
| :--- | :--- |
| **会不会封号？** | **不会。** 脚本不读写任何游戏内存，仅调整 `SGuard64.exe` 的启动顺序，属于纯净的环境引导行为，完全符合官方机制。 |
| **提示"[ENV ERROR]"** | 确认 `.bat` 文件是在完整的项目目录结构下运行的，不要单独复制启动文件。 |
| **快捷方式打不开？** | 若移动过项目目录，请重新双击 `创建桌面图标.bat`。快捷方式会自动更新到当前目录。 |
| **LOL 提示"[检测失败]"** | 确认英雄联盟已完整安装，且目录包含 `Game`、`Cross`、`Launcher`、`LeagueClient` 子目录。修复安装后重新运行脚本即可。 |
| **为什么不推荐 WeGame 模式？** | WeGame 更新后，疑似会接管并重启 ACE 相关进程，使脚本提前启动 `SGuard64.exe` 的优化失效。该入口仅为兼容使用习惯而保留。 |
| **DF 提示"[检测失败]"** | 确认三角洲行动已完整安装；官方模式需单独安装 `delta_force_launcher.exe`，Steam 模式需已安装 Steam 客户端。 |
| **提示"无法启动组件"** | 右键点击 `.bat` 文件，选择 **"以管理员身份运行"**。 |

---

如果这个工具帮到了你，欢迎点一个 **Star** ⭐ 支持一下~

祝你在召唤师峡谷与烽火地带都丝滑稳定、永不掉帧！ 🚩
