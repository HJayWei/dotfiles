# macOS 開發環境 Dotfiles

這是一個用於快速建立和配置 macOS 個人開發環境的自動化工具集，使用 GNU Stow 管理符號連結，確保配置檔案的模組化和可維護性。

## 專案架構

```
dotfiles/
├── alacritty/      # Alacritty 終端機配置
├── bat/            # Bat (cat 替代品) 主題配置
├── codeium/        # Codeium/Windsurf IDE 配置
├── docker/         # Docker 客戶端配置
├── espanso/        # Espanso 文字擴展工具配置
├── ghostty/        # Ghostty 終端機配置
├── git/            # Git 配置 (含 Delta 差異檢視器)
├── installer/      # Go 安裝工具 (推薦使用)
├── nvim/           # Neovim 配置 (作為 git submodule)
├── openspec/       # OpenSpec 專案規格管理
├── prettier/       # Prettier 程式碼格式化配置
├── ssh/            # SSH 連線配置
├── zellij/         # Zellij 終端多工器配置
├── zsh/            # Zsh Shell 配置 (含 Zinit、P10k)
├── Brewfile        # Homebrew 命令列工具清單
├── BrewCask        # Homebrew Cask 應用程式清單
└── install.sh      # Shell 安裝腳本 (傳統方式)
```

## 核心功能

### 1. 套件管理
- **Homebrew**: macOS 套件管理器
- **Brewfile**: 命令列工具安裝清單，包含開發必備工具
- **BrewCask**: GUI 應用程式安裝清單，涵蓋終端機、瀏覽器、IDE、資料庫工具等

### 2. Shell 環境 (Zsh)
- **Zinit**: 高效能 Zsh 插件管理器
- **Powerlevel10k**: 強大的 Shell 提示主題
- **整合工具**:
  - `fzf`: 模糊搜尋工具
  - `eza`: 現代化的 ls 替代品
  - `zoxide`: 智能目錄跳轉
  - `bat`: 帶語法高亮的 cat 替代品
- **插件**:
  - `zsh-completions`: 自動補全增強
  - `zsh-autosuggestions`: 命令建議
  - `fast-syntax-highlighting`: 語法高亮
  - `zsh-history-substring-search`: 歷史搜尋

### 3. 終端機環境
- **Alacritty**: GPU 加速終端機 (主要使用)
- **Ghostty**: 原生 UI 終端機 (備選)
- **Zellij**: 終端多工器 (類似 tmux)
- **字型支援**: 多種 Nerd Font，預設使用 Maple Mono Normal NF CN

### 4. 開發工具配置

#### Git
- **Delta**: 增強的 Git 差異檢視器
- **別名**: 簡化常用 Git 指令 (`co`, `st`, `ch`, `br`, `lg` 等)
- **配置**: 差異檢視、合併策略、彩色輸出

#### Neovim
- 完整的 IDE 配置 (透過 git submodule 管理)
- 支援 LSP、自動補全、語法高亮等功能
- 儲存庫: [HJayWei/dot-nvim](https://github.com/HJayWei/dot-nvim.git)

#### 程式語言環境
- **asdf**: 多語言版本管理器
- **Rust**: 透過 rustup 安裝
- **Go**: 透過 Homebrew 安裝
- **PHP 8.2**: 特定版本配置
- **Node.js/Python**: 透過 asdf 管理

### 5. 生產力工具
- **Espanso**: 文字擴展工具
- **Docker**: 容器化開發環境
- **Prettier**: 程式碼格式化工具

## 安裝前置需求

- macOS (Apple Silicon 或 Intel)
- 網路連線
- 管理員權限

## 快速安裝

### 方法一：使用安裝腳本 (Shell)

```bash
# 1. 克隆專案到家目錄
cd ~
git clone <你的倉庫 URL> dotfiles

# 2. 進入專案目錄
cd dotfiles

# 3. 執行安裝腳本
chmod +x install.sh
./install.sh
```

### 方法二：使用 Go 安裝工具（推薦）

Go 版本提供更好的錯誤處理、互動式體驗和彩色輸出。

```bash
# 1. 克隆專案
cd ~
git clone <你的倉庫 URL> dotfiles
cd dotfiles/installer

# 2. 使用 Makefile 執行（推薦）
make install

# 或直接執行（不編譯）
make run

# 或使用 go run
go run main.go
```

**Go 工具的優勢**:
- ✓ 智能偵測已安裝的工具
- ✓ 詳細的錯誤處理與回報
- ✓ 失敗時可選擇繼續或中斷
- ✓ 彩色終端輸出，清楚易讀
- ✓ 自動跳過已存在的配置

> 詳細使用方式請參考 [`installer/README.md`](installer/README.md)

## 安裝流程說明

安裝腳本會依序執行以下步驟：

1. **安裝 Xcode Command Line Tools**
   - 提供編譯必要的工具鏈

2. **安裝 Homebrew**
   - 自動偵測安裝路徑 (Apple Silicon: `/opt/homebrew`, Intel: `/usr/local`)

3. **安裝命令列工具 (Brewfile)**
   - 版本管理工具 (asdf, git)
   - 開發工具 (docker, neovim, lazygit)
   - CLI 工具 (fzf, ripgrep, bat, eza)

4. **安裝 Nerd Fonts**
   - CommitMono Nerd Font
   - FiraCode Nerd Font
   - MesloLG Nerd Font
   - Hack Nerd Font
   - Maple Mono Nerd Font
   - BlexMono Nerd Font

5. **安裝 GUI 應用程式 (BrewCask)**
   - 終端機: Alacritty, Ghostty
   - 瀏覽器: Arc, Firefox, Chrome, Brave 等
   - IDE: Windsurf, VSCode, Zed, Neovide
   - 生產力工具: Notion, Obsidian, Raycast
   - 開發工具: Docker, Postman, DBNgin

6. **初始化 Git Submodule**
   - 同步 Neovim 配置

7. **部署配置檔案 (GNU Stow)**
   - 建立符號連結到 `$HOME`
   - 各模組獨立管理，易於維護

8. **安裝 Rust**
   - 透過 rustup 安裝最新穩定版

9. **建立專案目錄**
   - `~/Project`: 預設專案工作目錄

## 配置模組詳細說明

### Alacritty (`alacritty/`)
終端機配置，位於 `~/.config/alacritty/alacritty.toml`

**主要設定**:
- 字型: Maple Mono Normal NF CN, 13pt
- 背景透明度: 0.7
- 主題: Wombat
- 快捷鍵: Alt+方向鍵跳字、Cmd+Enter 最大化

### Zsh (`zsh/`)
Shell 環境配置

**檔案**:
- `.zshrc`: 主配置檔案
- `.zprofile`: 登入時載入的配置
- `.p10k.zsh`: Powerlevel10k 主題配置
- `fzf-git/`: FZF Git 整合腳本

**功能**:
- 自動補全優化
- 歷史記錄管理 (10000 筆)
- 語法高亮和建議
- FZF 模糊搜尋整合
- 自訂別名 (ls→eza, cat→bat, cd→z)

### Git (`git/`)
版本控制配置

**檔案**:
- `.gitconfig`: Git 全域配置
- `.gitignore_global`: 全域忽略規則
- `delta/themes.gitconfig`: Delta 主題配置

**特色**:
- Delta 美化差異檢視 (side-by-side 模式)
- 大量 Git 別名簡化操作
- 預設分支為 `main`
- 整合 Neovim 作為編輯器

### Neovim (`nvim/`)
現代化的 Vim 編輯器

**特點**:
- 獨立 Git Submodule 管理
- LazyVim 配置框架
- LSP、自動補全、Tree-sitter
- 詳見: [dot-nvim README](https://github.com/HJayWei/dot-nvim)

### Bat (`bat/`)
語法高亮的 cat 替代品

**配置**:
- 主題: Dracula
- 快取主題以提升效能

### Zellij (`zellij/`)
Rust 編寫的終端多工器

**配置位置**: `~/.config/zellij/config.kdl`
- 自訂布局和插件支援

### Prettier (`prettier/`)
程式碼格式化工具

**規則**:
- 使用單引號
- 4 空格縮排 (預設)
- 行寬限制 100 字元
- 尾隨逗號
- 特定檔案類型覆寫規則

### SSH (`ssh/`)
SSH 連線配置

**位置**: `~/.ssh/config`
- 管理遠端伺服器連線設定

### Docker (`docker/`)
Docker 客戶端配置

**位置**: `~/.docker/config.json`

### Espanso (`espanso/`)
文字擴展工具配置

**位置**: `~/Library/Application Support/espanso/`

### Ghostty (`ghostty/`)
輕量級終端機配置

**設定**:
- 背景透明度: 0.8
- 字型: Maple Mono Normal NF CN, 13pt
- Option 鍵作為 Alt

## 常用操作

### 新增或修改配置

```bash
# 1. 編輯對應模組的配置檔案
cd ~/dotfiles/zsh
vim .zshrc

# 2. 重新部署 (如果需要)
stow -R zsh

# 3. 重新載入配置
source ~/.zshrc
```

### 新增配置模組

```bash
# 1. 建立新模組目錄
mkdir -p ~/dotfiles/新工具名稱/.config/新工具名稱

# 2. 新增配置檔案
# ...

# 3. 使用 stow 部署
cd ~/dotfiles
stow 新工具名稱
```

### 移除配置模組

```bash
# 取消符號連結
cd ~/dotfiles
stow -D 模組名稱
```

### 更新 Homebrew 套件

```bash
# 更新 Homebrew
brew update

# 升級所有套件
brew upgrade

# 安裝 Brewfile 中的新增套件
cd ~/dotfiles
brew bundle install --file Brewfile
brew bundle install --file BrewCask
```

### 同步 Neovim 配置

```bash
# 更新 submodule
cd ~/dotfiles
git submodule update --remote nvim/.config/nvim

# 重新部署
stow -R nvim
```

## 備份與還原

### 備份現有配置

```bash
# 在安裝前備份現有配置
mkdir -p ~/dotfiles_backup
cp -r ~/.zshrc ~/.gitconfig ~/.config ~/dotfiles_backup/
```

### 還原配置

```bash
# 取消所有 stow 連結
cd ~/dotfiles
for dir in */; do stow -D "${dir%/}"; done

# 還原備份
cp -r ~/dotfiles_backup/* ~/
```

## 自訂與擴展

### 修改 Brewfile

編輯 `Brewfile` 或 `BrewCask` 新增你需要的工具：

```ruby
# Brewfile
brew "your-cli-tool"

# BrewCask
cask "your-app"
```

### 修改 Shell 主題

執行 Powerlevel10k 配置精靈：

```bash
p10k configure
```

### 修改終端機主題

Alacritty 主題位於 `~/.config/alacritty/themes/`，修改 `alacritty.toml` 中的導入路徑。

## 疑難排解

### Homebrew 找不到

確認 Homebrew 已正確安裝並設定環境變數：

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
# 或
eval "$(/usr/local/bin/brew shellenv)"     # Intel
```

### Stow 衝突

如果目標位置已有檔案，stow 會報錯。解決方法：

```bash
# 備份現有檔案
mv ~/.zshrc ~/.zshrc.backup

# 重新執行 stow
stow zsh
```

### Submodule 未初始化

```bash
git submodule init
git submodule update --init --recursive
```

### 字型未正確顯示

確認終端機使用 Nerd Font：
1. 終端機偏好設定 → 字型
2. 選擇任一 Nerd Font (建議 Maple Mono Normal NF CN)

## 維護建議

1. **定期更新**: 每週執行 `brew update && brew upgrade`
2. **版本控制**: 配置變更後提交到 Git
3. **模組化**: 保持每個工具的配置獨立
4. **文件化**: 記錄自訂設定的原因

## 授權

本專案供個人使用，請根據需求自行調整。

## 相關資源

- [Homebrew](https://brew.sh/)
- [GNU Stow](https://www.gnu.org/software/stow/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [LazyVim](https://www.lazyvim.org/)
- [Alacritty](https://alacritty.org/)
- [Neovim](https://neovim.io/)
