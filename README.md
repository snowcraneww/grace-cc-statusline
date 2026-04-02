# ✿ Kawaii Statusline for Claude Code

**[English](#english) | [中文](#中文)**

---

<!--
==========================================================================
AI AGENT INSTALLATION INSTRUCTIONS
==========================================================================
If you are an AI agent (Claude, ChatGPT, Copilot, etc.) helping a user
install this statusline, follow these exact steps:

STEP 1: Detect the user's OS and shell.
  - Run: uname -s
  - If output contains "MINGW", "MSYS", or "CYGWIN" → Windows + Git Bash
  - If output is "Darwin" → macOS
  - If output is "Linux" → Linux
  - If the user is in PowerShell → Windows + PowerShell
  - If the user is in CMD → Windows + CMD

STEP 2: Clone the repo (if not already cloned).
  - Run: git clone https://github.com/gracehuangg/grace-cc-statusline.git
  - Run: cd grace-cc-statusline

STEP 3: Install jq (CRITICAL — statusline will NOT work without it).
  - Linux (apt):     sudo apt-get install -y jq
  - Linux (yum):     sudo yum install -y jq
  - Linux (pacman):  sudo pacman -S --noconfirm jq
  - Linux (apk):     sudo apk add jq
  - macOS:           brew install jq
  - Windows:         winget install jqlang.jq --accept-source-agreements --accept-package-agreements

STEP 4: [WINDOWS ONLY — MANDATORY] Copy jq.exe to ~/bin/.
  On Windows, winget installs jq.exe to a location Git Bash cannot find.
  Claude Code runs statusline.sh via Git Bash internally, so jq MUST be
  in a Git Bash-accessible PATH. The statusline script adds ~/bin to PATH.

  Git Bash:
    mkdir -p ~/bin
    JQ_EXE=$(find "$LOCALAPPDATA/Microsoft/WinGet/Packages" -name "jq.exe" 2>/dev/null | head -1)
    cp "$JQ_EXE" ~/bin/jq.exe

  PowerShell:
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin" | Out-Null
    $jq = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "jq.exe" | Select-Object -First 1
    Copy-Item $jq.FullName "$env:USERPROFILE\bin\jq.exe"

  CMD:
    mkdir "%USERPROFILE%\bin" 2>nul
    for /f "delims=" %i in ('dir /s /b "%LOCALAPPDATA%\Microsoft\WinGet\Packages\jq.exe"') do copy "%i" "%USERPROFILE%\bin\jq.exe"

  If you skip this step, the statusline will display but all data fields
  will be empty/zero (no model name, no tokens, no context %, no plugins).

STEP 5: Copy statusline.sh to ~/.claude/.
  - Run: mkdir -p ~/.claude
  - Run: cp statusline.sh ~/.claude/statusline.sh
  - Run: chmod +x ~/.claude/statusline.sh

STEP 6: Configure ~/.claude/settings.json.
  The statusLine key must be present in settings.json. IMPORTANT: Do NOT
  overwrite the entire file — merge with existing content.

  If the file exists, use jq to merge:
    jq '. + {"statusLine":{"type":"command","command":"bash ~/.claude/statusline.sh"}}' ~/.claude/settings.json > /tmp/settings_tmp.json && mv /tmp/settings_tmp.json ~/.claude/settings.json

  If the file does not exist:
    echo '{"statusLine":{"type":"command","command":"bash ~/.claude/statusline.sh"}}' > ~/.claude/settings.json

STEP 7: Verify installation.
  - Run: export PATH="$HOME/bin:$PATH" && echo '{"model":{"display_name":"Test"}}' | bash ~/.claude/statusline.sh
  - If you see "✿ 🤖 Test" in the output, installation is successful.
  - If you see "jq: command not found", go back to STEP 3/4.

STEP 8: Tell the user to restart their Claude Code session.

COMMON FAILURE: On Windows, the #1 issue is jq not in Git Bash PATH.
  Symptoms: statusline appears but shows "Unknown" model, 0% context, 0 plugins.
  Fix: Repeat STEP 4.
==========================================================================
-->

<a id="english"></a>

## English

A beautiful, info-rich status line for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that works on **Linux**, **macOS**, and **Windows** (Git Bash / PowerShell / CMD).

### Features

- **Model indicator** — icon + name (Opus 🎵 / Sonnet 📝 / Haiku 🍃)
- **Project folder** — current working directory name
- **Context window** — animated progress bar with color-coded usage (🌱→🧠→⚡→🔥)
- **Token stats** — cumulative input/output tokens
- **Cache stats** — cache read/write tokens
- **Cost tracker** — session cost in USD
- **Git status** — branch, modified/staged/untracked files, ahead/behind
- **Skills / Plugins / MCP** — counts of installed extensions

### Quick Install

#### Linux / macOS

```bash
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline
bash install.sh
```

The installer auto-detects your package manager and installs `jq`:

| OS | Package Manager | Command (auto-run by installer) |
|----|----------------|--------------------------------|
| Ubuntu / Debian | apt | `sudo apt-get install -y jq` |
| CentOS / RHEL / Fedora | yum | `sudo yum install -y jq` |
| Arch Linux | pacman | `sudo pacman -S --noconfirm jq` |
| Alpine | apk | `sudo apk add jq` |
| macOS | Homebrew | `brew install jq` |

> If your package manager is not listed, install `jq` manually first: https://jqlang.github.io/jq/download/

#### Windows — Git Bash

```bash
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline
bash install.sh
```

#### Windows — PowerShell

```powershell
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline

# 1. Install jq
winget install jqlang.jq

# 2. Copy jq.exe to ~/bin/ so Git Bash can find it (CRITICAL!)
$jqPath = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "jq.exe" | Select-Object -First 1
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin" | Out-Null
Copy-Item $jqPath.FullName "$env:USERPROFILE\bin\jq.exe"

# 3. Copy statusline script
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
Copy-Item statusline.sh "$env:USERPROFILE\.claude\statusline.sh"

# 4. Add statusLine config to settings.json
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
} else {
    $settings = @{}
}
$settings | Add-Member -Force -MemberType NoteProperty -Name "statusLine" -Value @{
    type = "command"
    command = "bash ~/.claude/statusline.sh"
}
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
```

#### Windows — CMD

```cmd
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline

:: 1. Install jq
winget install jqlang.jq

:: 2. Copy jq.exe to ~/bin/ so Git Bash can find it (CRITICAL!)
mkdir "%USERPROFILE%\bin" 2>nul
for /f "delims=" %%i in ('dir /s /b "%LOCALAPPDATA%\Microsoft\WinGet\Packages\jq.exe"') do copy "%%i" "%USERPROFILE%\bin\jq.exe"

:: 3. Copy statusline script
mkdir "%USERPROFILE%\.claude" 2>nul
copy statusline.sh "%USERPROFILE%\.claude\statusline.sh"
```

Then manually add the `statusLine` config to `%USERPROFILE%\.claude\settings.json` (see [Manual Install](#manual-install)).

After installing, **restart your Claude Code session**.

### Manual Install

1. Install [jq](https://jqlang.github.io/jq/download/)
2. Copy `statusline.sh` to `~/.claude/statusline.sh`
3. Add to `~/.claude/settings.json` (merge, do not overwrite existing settings):
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline.sh"
     }
   }
   ```
4. **Windows only:** copy `jq.exe` to `~/bin/` (see [jq PATH Setup](#windows-jq-path-setup-important))
5. Restart Claude Code

### Requirements

- **Claude Code** CLI
- **jq** — JSON processor (auto-installed by `install.sh`)
- **Bash** — available on all platforms (Git Bash on Windows)

### Windows: jq PATH Setup (Important!)

On Windows, `jq` must be accessible from **Git Bash** for the statusline to work. Claude Code uses Git Bash internally to run the statusline script, so even if `jq` is installed via `winget`, it won't work unless it's in a PATH that Git Bash can see.

The installer handles this automatically, but if you see that the statusline shows **no model name, no context data, and all counts are 0**, it means `jq` is not in the Git Bash PATH.

**Fix — copy `jq.exe` to `~/bin/`:**

Git Bash:
```bash
mkdir -p ~/bin
JQ_EXE=$(find "$LOCALAPPDATA/Microsoft/WinGet/Packages" -name "jq.exe" 2>/dev/null | head -1)
cp "$JQ_EXE" ~/bin/jq.exe
```

PowerShell:
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin" | Out-Null
$jqPath = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "jq.exe" | Select-Object -First 1
Copy-Item $jqPath.FullName "$env:USERPROFILE\bin\jq.exe"
```

CMD:
```cmd
mkdir "%USERPROFILE%\bin" 2>nul
for /f "delims=" %%i in ('dir /s /b "%LOCALAPPDATA%\Microsoft\WinGet\Packages\jq.exe"') do copy "%%i" "%USERPROFILE%\bin\jq.exe"
```

Verify in Git Bash:
```bash
export PATH="$HOME/bin:$PATH"
jq --version
```

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Model shows "Unknown", all data is 0 | `jq` not found by Git Bash | Copy `jq.exe` to `~/bin/` (see above) |
| Statusline doesn't appear at all | `settings.json` not configured | Run `bash install.sh` or add config manually |
| Git status not showing | Not in a git repository | Normal — git section only appears in repos |
| Plugin count is 0 | No plugins installed | Install plugins via Claude Code |
| macOS: `brew` not found | Homebrew not installed | Install from https://brew.sh |
| Linux: `sudo` permission denied | No sudo access | Install `jq` via your admin or download manually |

### Uninstall

```bash
rm ~/.claude/statusline.sh
```

Then remove the `"statusLine"` block from `~/.claude/settings.json`.

### License

MIT

---

<a id="中文"></a>

## 中文

<!--
==========================================================================
AI 助手安装说明
==========================================================================
如果你是 AI 助手（Claude、ChatGPT、Copilot 等）正在帮用户安装此状态栏，
请严格按以下步骤操作：

第 1 步：检测用户的操作系统和终端。
  - 执行: uname -s
  - 输出包含 "MINGW"、"MSYS" 或 "CYGWIN" → Windows + Git Bash
  - 输出为 "Darwin" → macOS
  - 输出为 "Linux" → Linux
  - 如果用户在 PowerShell 中 → Windows + PowerShell
  - 如果用户在 CMD 中 → Windows + CMD

第 2 步：克隆仓库（如果尚未克隆）。
  - 执行: git clone https://github.com/gracehuangg/grace-cc-statusline.git
  - 执行: cd grace-cc-statusline

第 3 步：安装 jq（关键 — 没有 jq 状态栏将完全无法工作）。
  - Linux (apt):     sudo apt-get install -y jq
  - Linux (yum):     sudo yum install -y jq
  - Linux (pacman):  sudo pacman -S --noconfirm jq
  - Linux (apk):     sudo apk add jq
  - macOS:           brew install jq
  - Windows:         winget install jqlang.jq --accept-source-agreements --accept-package-agreements

第 4 步：[仅 Windows — 必须执行] 将 jq.exe 复制到 ~/bin/。
  在 Windows 上，winget 将 jq.exe 安装到 Git Bash 无法访问的路径。
  Claude Code 内部通过 Git Bash 运行 statusline.sh，因此 jq 必须在
  Git Bash 可访问的 PATH 中。statusline.sh 脚本会自动将 ~/bin 加入 PATH。

  Git Bash:
    mkdir -p ~/bin
    JQ_EXE=$(find "$LOCALAPPDATA/Microsoft/WinGet/Packages" -name "jq.exe" 2>/dev/null | head -1)
    cp "$JQ_EXE" ~/bin/jq.exe

  PowerShell:
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin" | Out-Null
    $jq = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "jq.exe" | Select-Object -First 1
    Copy-Item $jq.FullName "$env:USERPROFILE\bin\jq.exe"

  CMD:
    mkdir "%USERPROFILE%\bin" 2>nul
    for /f "delims=" %i in ('dir /s /b "%LOCALAPPDATA%\Microsoft\WinGet\Packages\jq.exe"') do copy "%i" "%USERPROFILE%\bin\jq.exe"

  如果跳过此步骤，状态栏会显示但所有数据字段为空/零
  （无模型名、无 Token 数、无上下文百分比、无插件数量）。

第 5 步：将 statusline.sh 复制到 ~/.claude/。
  - 执行: mkdir -p ~/.claude
  - 执行: cp statusline.sh ~/.claude/statusline.sh
  - 执行: chmod +x ~/.claude/statusline.sh

第 6 步：配置 ~/.claude/settings.json。
  statusLine 字段必须存在于 settings.json 中。重要：不要覆盖整个文件，
  要与现有内容合并。

  如果文件已存在，用 jq 合并:
    jq '. + {"statusLine":{"type":"command","command":"bash ~/.claude/statusline.sh"}}' ~/.claude/settings.json > /tmp/settings_tmp.json && mv /tmp/settings_tmp.json ~/.claude/settings.json

  如果文件不存在:
    echo '{"statusLine":{"type":"command","command":"bash ~/.claude/statusline.sh"}}' > ~/.claude/settings.json

第 7 步：验证安装。
  - 执行: export PATH="$HOME/bin:$PATH" && echo '{"model":{"display_name":"Test"}}' | bash ~/.claude/statusline.sh
  - 如果输出中看到 "✿ 🤖 Test"，安装成功。
  - 如果看到 "jq: command not found"，回到第 3/4 步。

第 8 步：告诉用户重启 Claude Code 会话。

最常见故障：在 Windows 上，头号问题是 jq 不在 Git Bash PATH 中。
  症状：状态栏显示但模型为 "Unknown"、上下文 0%、插件 0。
  修复：重新执行第 4 步。
==========================================================================
-->

一个漂亮的 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 状态栏插件，支持 **Linux**、**macOS** 和 **Windows**（Git Bash / PowerShell / CMD）。

### 功能特性

- **模型指示器** — 图标 + 名称（Opus 🎵 / Sonnet 📝 / Haiku 🍃）
- **项目文件夹** — 当前工作目录名称
- **上下文窗口** — 带颜色编码的进度条（🌱→🧠→⚡→🔥）
- **Token 统计** — 累计输入/输出 Token 数
- **缓存统计** — 缓存读写 Token 数
- **费用追踪** — 会话费用（美元）
- **Git 状态** — 分支、修改/暂存/未跟踪文件、领先/落后提交数
- **Skills / Plugins / MCP** — 已安装扩展的数量统计

### 快速安装

#### Linux / macOS

```bash
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline
bash install.sh
```

安装脚本会自动检测你的包管理器并安装 `jq`：

| 操作系统 | 包管理器 | 自动执行的命令 |
|---------|---------|--------------|
| Ubuntu / Debian | apt | `sudo apt-get install -y jq` |
| CentOS / RHEL / Fedora | yum | `sudo yum install -y jq` |
| Arch Linux | pacman | `sudo pacman -S --noconfirm jq` |
| Alpine | apk | `sudo apk add jq` |
| macOS | Homebrew | `brew install jq` |

> 如果你的包管理器不在上表中，请先手动安装 `jq`：https://jqlang.github.io/jq/download/

#### Windows — Git Bash

```bash
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline
bash install.sh
```

#### Windows — PowerShell

```powershell
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline

# 1. 安装 jq
winget install jqlang.jq

# 2. 将 jq.exe 复制到 ~/bin/，让 Git Bash 能找到（关键步骤！）
$jqPath = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "jq.exe" | Select-Object -First 1
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin" | Out-Null
Copy-Item $jqPath.FullName "$env:USERPROFILE\bin\jq.exe"

# 3. 复制状态栏脚本
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
Copy-Item statusline.sh "$env:USERPROFILE\.claude\statusline.sh"

# 4. 将 statusLine 配置写入 settings.json
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
} else {
    $settings = @{}
}
$settings | Add-Member -Force -MemberType NoteProperty -Name "statusLine" -Value @{
    type = "command"
    command = "bash ~/.claude/statusline.sh"
}
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
```

#### Windows — CMD

```cmd
git clone https://github.com/gracehuangg/grace-cc-statusline.git
cd grace-cc-statusline

:: 1. 安装 jq
winget install jqlang.jq

:: 2. 将 jq.exe 复制到 ~/bin/，让 Git Bash 能找到（关键步骤！）
mkdir "%USERPROFILE%\bin" 2>nul
for /f "delims=" %%i in ('dir /s /b "%LOCALAPPDATA%\Microsoft\WinGet\Packages\jq.exe"') do copy "%%i" "%USERPROFILE%\bin\jq.exe"

:: 3. 复制状态栏脚本
mkdir "%USERPROFILE%\.claude" 2>nul
copy statusline.sh "%USERPROFILE%\.claude\statusline.sh"
```

然后手动将 `statusLine` 配置添加到 `%USERPROFILE%\.claude\settings.json`（参见[手动安装](#手动安装)）。

安装完成后，**重启 Claude Code 会话**即可生效。

### 手动安装

1. 安装 [jq](https://jqlang.github.io/jq/download/)
2. 将 `statusline.sh` 复制到 `~/.claude/statusline.sh`
3. 在 `~/.claude/settings.json` 中添加（与现有配置合并，不要覆盖）：
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline.sh"
     }
   }
   ```
4. **仅 Windows：** 将 `jq.exe` 复制到 `~/bin/`（参见 [jq 环境变量配置](#windows-jq-环境变量配置重要)）
5. 重启 Claude Code

### 系统要求

- **Claude Code** CLI
- **jq** — JSON 处理工具（`install.sh` 会自动安装）
- **Bash** — 所有平台均可用（Windows 上使用 Git Bash）

### Windows：jq 环境变量配置（重要！）

在 Windows 上，`jq` 必须能被 **Git Bash** 找到，状态栏才能正常工作。Claude Code 内部使用 Git Bash 来运行状态栏脚本，所以即使通过 `winget` 安装了 `jq`，如果它不在 Git Bash 的 PATH 中，状态栏仍然**无法获取任何数据**。

安装脚本会自动处理这个问题，但如果你发现状态栏显示**模型名为空、上下文数据全为 0、插件数量为 0**，说明 `jq` 不在 Git Bash 的 PATH 中。

**修复方法 — 将 `jq.exe` 复制到 `~/bin/`：**

Git Bash：
```bash
mkdir -p ~/bin
JQ_EXE=$(find "$LOCALAPPDATA/Microsoft/WinGet/Packages" -name "jq.exe" 2>/dev/null | head -1)
cp "$JQ_EXE" ~/bin/jq.exe
```

PowerShell：
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin" | Out-Null
$jqPath = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "jq.exe" | Select-Object -First 1
Copy-Item $jqPath.FullName "$env:USERPROFILE\bin\jq.exe"
```

CMD：
```cmd
mkdir "%USERPROFILE%\bin" 2>nul
for /f "delims=" %%i in ('dir /s /b "%LOCALAPPDATA%\Microsoft\WinGet\Packages\jq.exe"') do copy "%%i" "%USERPROFILE%\bin\jq.exe"
```

验证（在 Git Bash 中）：
```bash
export PATH="$HOME/bin:$PATH"
jq --version
# 应输出 jq-1.x
```

### 常见问题

| 现象 | 原因 | 解决方法 |
|-----|------|---------|
| 模型显示 "Unknown"，所有数据为 0 | Git Bash 找不到 `jq` | 将 `jq.exe` 复制到 `~/bin/`（见上方） |
| 状态栏完全不显示 | `settings.json` 未配置 | 运行 `bash install.sh` 或手动添加配置 |
| Git 状态不显示 | 不在 Git 仓库中 | 正常现象 — Git 信息仅在仓库中显示 |
| 插件数量为 0 | 未安装插件 | 通过 Claude Code 安装插件 |
| macOS：找不到 `brew` | 未安装 Homebrew | 从 https://brew.sh 安装 |
| Linux：`sudo` 权限不足 | 无 sudo 权限 | 联系管理员安装 `jq`，或手动下载二进制文件 |

### 卸载

```bash
rm ~/.claude/statusline.sh
```

然后从 `~/.claude/settings.json` 中删除 `"statusLine"` 配置块。

### 许可证

MIT
