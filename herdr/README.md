# herdr 設定

個人的 [herdr](https://herdr.dev) 設定，涵蓋 macOS 與 Windows + WSL2（Debian）。涵蓋三個程式：

| 程式 | macOS | Windows + WSL | 用途 |
|---|---|---|---|
| herdr（TUI / CLI） | Homebrew | WSL，mise | 終端機裡的工作區管理 |
| herdr-app | Homebrew cask（限 Apple Silicon） | Windows，scoop | 桌面版視窗 |
| herdr-core（`hc`） | 由 herdr-app 補裝 | Windows 與 WSL 各一份 | app 背後實際執行終端機的程式 |

## 新機器安裝

### macOS

`install.sh` 已包含全部步驟。既有的 mac 只想補 herdr 時：

```bash
cd ~/dotfiles
brew install herdr && brew install --cask herdr-app
mkdir -p ~/.local/bin ~/.config/herdr ~/.config/herdr-app/{layouts,mods,themes}
stow herdr
```

- `stow` 回報衝突，代表先前開過 herdr / herdr-app、已有同名設定檔，移走後重跑。
- 先 `mkdir` 是為了讓 stow 只連 repo 裡有的東西；整個目錄連過去，記錄與 socket 會寫進 repo。
  不用 `--no-folding`，因為 mod 要連整個資料夾，app 才偵測得到修改並即時重載。
- Homebrew 沒有 herdr-core，第一次開 app 時依提示補裝。

### Windows + WSL

先裝好 WSL（Debian），之後都在 WSL 裡執行：

```bash
git clone https://github.com/HJayWei/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh              # 選 wsl
```

1. `chezmoi apply` 裝好 WSL 端（herdr、設定、bubblewrap、linger），並把 app 設定複製到 Windows。
2. 最後詢問是否在 Windows 裝 herdr-app，答 `y` 會執行 `chezmoi/windows/setup-herdr.ps1`：
   裝 scoop、git、herdr-app（連同 herdr-core），再把這個 WSL 加成 `wsl` 機器。不需要管理者權限。

可重複執行，已完成的步驟會跳過。之後要在 PowerShell 用 `scoop` 指令，需執行一次
`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`。

### 兩邊都要手動做的

- 開 app 後按 `ctrl+shift+l` 切到 `glass` 版面（主題 nord 由版面指定，不用另外選）。
- Windows 要用 `Maple Mono Normal NF CN`，需到 `%USERPROFILE%\.config\wezterm\fonts` 對 .ttf 右鍵「安裝」。
- 要在 herdr 看到 Codex 的狀態：`herdr integration install codex`。
- Claude 的整合（hook、statusline、skill）都在 `claude/.claude`，不要再跑
  `herdr integration install claude`：它會把 `settings.json` 的路徑改成絕對路徑。
  mac 由 `stow claude` 連結；**WSL 的 chezmoi 目前不處理 `~/.claude`**，新機器要自己連
  （`ln -s ~/dotfiles/claude/.claude ~/.claude`），否則沒有 Claude 的用量與狀態。

## 結構

```
herdr/                              ← stow 套件（mac）；WSL 由 chezmoi 連結到這裡
  .config/herdr/config.toml         ← TUI 主設定
  .local/bin/herdr-usage            ← 存下並顯示各 agent 的用量額度
  .config/herdr-app/                ← app 設定
    settings.json                   ← 個人設定
    themes/nord.json                ← nord 主題
    layouts/glass.json              ← 半透明版面（複製自內建的 main）
    mods/agent-usage/               ← 底部狀態列右側的用量額度顯示
    mods/status-bar/                ← 底部狀態列（複製自內建，拿掉快捷鍵提示）
chezmoi/dot_local/bin/executable_notify-send   ← 只給 WSL：把 TUI 通知轉成 Windows 通知
chezmoi/run_after_65-enable-linger.sh.tmpl     ← 只給 WSL
chezmoi/windows/herdr-app-sync.sh              ← app 設定在 repo 與 Windows 之間同步
chezmoi/windows/setup-herdr.ps1                ← Windows 端安裝
```

app 的設定目錄：mac 是 `~/.config/herdr-app`，Windows（scoop）是
`%USERPROFILE%\scoop\persist\herdr-app\data`。

## 在本機改了設定之後

| 環境 | 怎麼進 repo |
|---|---|
| mac（TUI 與 app）、WSL（TUI） | 是連結，改了就在 repo 裡，`git diff` 看得到，直接 commit |
| Windows 的 app | 是複製，在 WSL 執行 `~/dotfiles/chezmoi/windows/herdr-app-sync.sh pull` 再 commit |

- 忘了 `pull` 也不會被蓋掉：`chezmoi apply` 發現 Windows 上有 repo 沒出現過的內容，會略過並提示。
- `pull` 只取回 repo 已有的檔案。在 app 裡**新增**的版面、主題、mod 要先手動放進
  `herdr/.config/herdr-app/`。
- repo 的位置不能搬（連結是絕對路徑），搬了要重跑 `chezmoi apply` 或 `stow -R herdr`。

## herdr-core：把 WSL 加成機器

core 沒有設定檔，唯一的設定是讓 Windows 端的 core 認得 WSL。`setup-herdr.ps1` 會執行這一行：

```
hc machine add --via "wsl.exe -d Debian --cd ~ -e sh -c" --name wsl --install
```

- `--install` 會在 WSL 裡裝 Linux 版 core（`~/.local/bin/herdr-core`）。
- `--cd ~` 讓 WSL 端的 core 從家目錄啟動，否則新終端機會開在 `/mnt/c`。
- 之後在 app 裡先點進 `wsl` 機器的空間再建新空間，就會沿用 WSL。
- 檢查連線：`hc machine ls`，狀態應為 `connected`。

出問題時刪掉重加（都在 Windows 的 PowerShell 執行）：

```
hc machine ls          # 看目前有哪些機器與狀態
hc machine rm wsl      # 只是讓 Windows 端忘記它，WSL 裡的終端機和空間不會被刪
hc machine add --via "wsl.exe -d Debian --cd ~ -e sh -c" --name wsl --install
```

要在 `wsl` 機器上開空間才會用到它：側邊欄 `wsl` 那一組旁的 `+`。開在「This computer」
再進 `wsl` 的分頁屬於 Windows 的 core，裡面的 agent 用 `hc` 開的子 agent 不會出現在 app。

## Claude Code 的 skill

讓 Claude 能在 herdr 裡開其他 agent 並派工。兩個 skill 各管一個環境，放在全域的
`~/.claude/skills/`（實際存放在 dotfiles），開新的 Claude session 才會載入。

| skill | 適用環境 | 判斷條件 | agent 用的指令 |
|---|---|---|---|
| `herdr` | TUI 的 pane | `HERDR_ENV=1` | `herdr pane split`、`herdr agent start` … |
| `herdr-core` | herdr-app 的終端機 | `HC_TERMINAL_ID` 有值 | `hc run`、`hc send`、`hc wait` … |

`herdr`：內容就是 `herdr --skill` 的輸出。

```bash
mkdir -p ~/.claude/skills/herdr
herdr --skill > ~/.claude/skills/herdr/SKILL.md
```

`herdr-core`：`hc --skill` 只輸出手冊，沒有 skill 需要的檔頭，所以前 16 行是手寫的
（名稱、保守的觸發條件、使用前檢查 `HC_TERMINAL_ID`），後面才接手冊。升級 core 後保留
檔頭、只換手冊：

```bash
f=~/.claude/skills/herdr-core/SKILL.md
{ head -n 16 "$f"; hc --skill; } > "$f.new" && mv "$f.new" "$f"
```

兩個 skill 都只在明確要求用 herdr / `hc` 派工時才會動用。codex 要以 `--no-daemon` 啟動，
否則它的指令會跑在 hc 之外。

## 用量額度顯示（`herdr-usage`）

在 TUI 分頁列右側顯示各 agent 的用量額度，例如 `Claude 5h 59%(2h11m) 7d 39%(5d4h)`：
每個額度是用量百分比，括號內是距離重置還有多久。
資料和顯示分開：每個 agent 把額度存成一個檔案，顯示端只讀檔，不綁特定 agent。

```
agent 執行時 → herdr-usage save <agent> → ~/.cache/herdr-usage/<agent>.json
                                              ↓
              TUI 分頁列每 30 秒執行 herdr-usage show
```

- **Claude**：Claude Code 只把額度交給狀態列腳本，所以由
  `claude/.claude/scripts/statusline-command.sh` 呼叫 `herdr-usage save claude`（沒裝時略過）。

- **herdr-app**：`mods/agent-usage` 這個 mod 讀同一批檔案，顯示在 `glass` 版面底部狀態列的
  右側，依用量變色（50% 以上黃、80% 以上紅），倒數時間以次要文字色接在百分比後面。
  三個顏色是寫死的（`#7ee787`、`#f2cc60`、`#ff7b72`），因為 nord 的綠和紅偏灰、小字上不醒目。資料來源依序是：
  - 這台電腦，以及每台已連線的機器（例如把 WSL 加成的 `wsl`）：用 `sh` 讀檔。
  - 只在 Windows 上、本機讀不到時：執行 `wsl.exe --cd ~ -e .local/bin/herdr-usage dump`，向預設的
    WSL 發行版要資料。所以不把 WSL 加成機器、只在 PowerShell 分頁裡進 `wsl` 也看得到。
    代價是 app 開著時每 30 秒會呼叫一次 `wsl.exe`，WSL 不會因閒置而關閉。

  版面裡的對應設定是 `status-row` 這一列：左邊是 `status-bar`，右邊 600 像素是 `agent-usage`。
- **`status-bar`**：複製自內建的 `workspace-status`（0.1.16），只拿掉右側的
  「Ctrl+Shift+P commands」提示。複製品不會跟著 app 更新；指令面板仍可用 `ctrl+shift+p` 開啟。
  同時開著多個 Claude 時，每個 session 的狀態列都會存檔，而閒置 session 手上是舊數字，
  所以存檔時會和既有資料逐項比較：重置時間較晚的是新週期，採用；同一週期取用量較大者；
  更舊的丟掉。這樣數字不會因為某個閒置的 session 重畫狀態列而倒退。

- **Codex**：沒有可掛接的地方，但每次回應都會把額度寫進 session 紀錄
  （`~/.codex/sessions/`）。`herdr-usage refresh` 讀最新一個 session 檔裡最後一筆額度；
  `show` 和 app 的 mod 每次都會先執行它，所以不用改 Codex 的任何設定。
- **其他 agent**：還沒接。之後在 `herdr-usage` 加一個存檔分支，寫出同樣格式的檔案即可。
- 數字只在該 agent 執行時更新，不做定時查詢（定時觸發會消耗額度）。
- 重置時間已過的額度顯示為 0%、不顯示倒數；資料超過 60 分鐘會標出多久以前，例如 `(3h前)`。
- 需要 `jq`，且 `~/.local/bin` 要在 `PATH` 裡。

## 沒有放進來的檔案

| 檔案 | 原因 |
|---|---|
| app 的 `keys.json` | 維持原廠內容，app 更新時才會自動帶入新的預設快捷鍵；只要改過就不再自動更新 |
| app 內建的 `layouts/`、`mods/` | 都是原廠的，每次啟動會被覆寫（自己複製的 `glass` 有放） |
| core 的 `machines.json`、`core.json` 等 | 是執行狀態不是設定，內含機器識別碼 |

## TUI 設定重點

### 外觀

- 主題 `nord`，側邊欄指定實色背景 `sidebar_bg`。Alacritty 只會讓預設背景透明，
  有指定背景色的格子不透明，所以效果是「實心側邊欄 + 透明 pane」。
- `overlay0` 調亮：側邊欄的 spaces / new / menu / agents / priority / « 都用這個顏色，
  原本在透明背景上太暗。
- 狀態用符號（`status_indicators = "symbols"`），pane 邊框顯示 agent 名稱。
- 分頁列右側顯示 `ZOOM` 標記（只有 pane 放大時才出現）與日期時間。
- Claude 的 agent 列多一行終端機標題，可以看到它正在做什麼。

### 快捷鍵

prefix 維持預設的 `ctrl+b`（`ctrl+a` 會擋到 shell 的行首與 nvim 的數字遞增）。

| 按鍵 | 動作 |
|---|---|
| `prefix` → `alt+g` | lazygit 浮動視窗 |
| `prefix` → `alt+b` | btop 浮動視窗 |
| `prefix` → `t` | 臨時 shell，`exit` 後關閉 |
| `prefix` → `?` | 列出所有快捷鍵 |

### 通知

`[ui.toast] delivery = "system"` 讓 herdr 在 agent 完成或需要回應時發系統通知，
不發給目前所在的分頁。

macOS 走系統通知：有 `terminal-notifier` 就用它，否則用 `osascript`（會顯示成 Script Editor）。

herdr 在 Linux 上是呼叫 `notify-send --app-name Herdr -- <標題> [內文]`。WSL 裡沒有
通知服務，所以用 `chezmoi/dot_local/bin/executable_notify-send` 這個替身，改用 Windows 內建的
PowerShell 發 Windows 通知，不需要安裝任何東西。

- 通知來源會顯示成「Windows PowerShell」。
- 點通知不會跳回終端機。
- 橫幅沒跳出來時，先檢查 Windows 的「請勿打擾」。
- 腳本只處理標題加內文，`--` 之前的選項一律忽略。

## app 設定重點

- 終端機字型 `Maple Mono Normal NF CN`、大小 15，外觀固定深色。
- 主題 nord（`themes/nord.json`）。第 8 號色（亮黑）調亮為 `#8791a8`，zsh 自動建議的灰字
  在半透明背景上才看得清楚。
- 使用統計已關閉（`"telemetry": false`）。

### 半透明版面 `glass`

複製自內建的 `main` 版面（0.1.16），只在根節點多了這幾項：

| 設定 | 值 | 作用 |
|---|---|---|
| `theme` | `nord` | 新機器不必再到 Settings 選主題 |
| `window_blur` | `true` | 模糊視窗後方的內容，帶透明度的顏色才會透出桌面 |
| `colors.chrome` | `#2e3440a6` | 側邊欄、分頁列、底部狀態列，約 65% 不透明 |
| `colors.background` | `#2e344040` | 終端機與卡片底色，約 25% |
| `colors.canvas` | `#2e344000` | 卡片後方的畫布，完全透明 |
| `terminal_opacity` | `0.1` | 終端機自己的背景，越小越透 |

- 顏色最後兩碼是不透明度，`00` 全透明、`ff` 不透明。
- 這幾層是疊在一起的：canvas 墊在終端機下面，調它會連帶讓終端機變深。
- nvim 這類會自己畫背景色的程式維持實色，所以四周會露出 `terminal_padding`
  （`[6, 6]`，內建是 `[14, 12]`）那圈透明的留白。
- 複製出來的版面不會跟著 app 更新；用 `ctrl+shift+l` 可切回內建版面。
- 沒有設 `preview`，所以 Settings 裡的縮圖是空白外框。

## WSL 注意事項

- 關掉最後一個終端機視窗後，WSL 約 15 秒就會停掉整個 distro，TUI 的伺服器、WSL 端的
  core 和裡面的 agent 會一起被終止，再進來只會還原版面。
- app 側邊欄 `wsl` 旁的警告是 core 提醒「登出後程序不會保留」，它建議執行
  `sudo loginctl enable-linger -- <使用者>`；`65-enable-linger` 會在 systemd 啟用時執行它。
- agent 整合的狀態用 `herdr integration status` 檢查。
