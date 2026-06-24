# chezmoi 跨平台環境初始化(最小骨架)

用 [chezmoi](https://chezmoi.io) 的 **profile + template** 機制,在 macOS / Debian VM / 容器
等不同環境中,以同一份 source 部署「對應子集」的工具與設定。

這是一份**獨立試驗骨架**,放在 `dotfiles/chezmoi/`,不影響現有的 stow 結構。

## 三層 profile

| profile | 對應場景 | 部署內容 |
|---|---|---|
| `container` | docker / podman 用完即丟 | 僅 `system` 基礎套件 |
| `vm` | Debian 測試 VM | `system` + `mise` 現代 CLI/runtime,把工具串進 shell rc,並部署可攜別名/history、gitconfig 核心與 tmux(含 TPM 外掛) |
| `workstation` | mac m4 工作機 | 全部,含 nvim 設定、應用層工具(leaf 等),以及 `mise` 的 workstation tier 開發向 CLI |

profile 在 `chezmoi init` 時詢問一次(見 `.chezmoi.toml.tmpl`),之後所有
template / `.chezmoiignore` / 安裝腳本都依 `.profile` 分支。

## source root 放在子目錄(`.chezmoiroot`)

骨架刻意放在 repo 的 `chezmoi/` 子目錄以和 stow 隔離。repo 根目錄的
**`.chezmoiroot`**(內容為 `chezmoi`)會讓 chezmoi 自動把 source root 降到該子目錄——
因此 `chezmoi init <repo-url>` 能直接運作,不會誤把 repo 根目錄的 stow 檔當 dotfile 部署。

## 檔案結構

```
dotfiles/
├── .chezmoiroot                              # (repo 根)內容 "chezmoi",指定 source root
└── chezmoi/
    ├── .chezmoi.toml.tmpl                     # init 時詢問 profile
    ├── .chezmoidata.yaml                      # 套件清單 + 跨平台名稱映射(宣告層)
    ├── .chezmoiignore                         # 非 workstation 排除 nvim;非 vm 排除 .gitconfig 與 .config/tmux
    ├── dot_gitconfig.tmpl                     # vm-only;可攜核心(identity/alias/delta pager)
    ├── dot_config/
    │   ├── nvim/init.lua                      # workstation-only(其餘 profile 被忽略)
    │   ├── shell/env.sh.tmpl                  # 共通;PATH(.local/bin + mise shims)+ 可攜別名 + history
    │   └── tmux/tmux.conf.tmpl                # vm-only;Linux 可攜版(OSC52 剪貼簿,TPM 外掛)
    ├── run_onchange_before_10-install-system-packages.sh.tmpl   # 全 profile:apt/brew 基礎套件
    ├── run_onchange_before_20-install-mise-tools.sh.tmpl        # vm/workstation:mise + 現代 CLI
    ├── run_onchange_after_30-install-app-tools.sh.tmpl          # workstation:leaf 等應用層
    ├── run_onchange_after_40-wire-shell-rc.sh.tmpl              # 非 workstation:把 env.sh 串進 shell rc
    └── run_onchange_after_50-setup-tmux.sh.tmpl                 # vm:apt 裝 tmux + clone TPM + 裝外掛
```

## 試用(務必先 dry-run)

```sh
# 1. 安裝 chezmoi
#    mac:  brew install chezmoi
#    其他: sh -c "$(curl -fsSL get.chezmoi.io)"

# 2a. 從遠端 URL 初始化(.chezmoiroot 會自動進 chezmoi/,並詢問 profile)
#     ⚠️ 前提:chezmoi/ 骨架所在分支需為該 repo 的預設分支
chezmoi init https://github.com/HJayWei/dotfiles.git

# 2b. 或:先手動 clone(例如要用尚未合併的分支),再以環境變數固定 source
git clone https://github.com/HJayWei/dotfiles.git ~/dotfiles
export CHEZMOI_SOURCE_DIR="$HOME/dotfiles"   # 設一次,之後所有指令免帶 --source
chezmoi init                                  # 詢問 profile

# 3. 預覽會做什麼(強烈建議先看)
chezmoi apply --dry-run --verbose

# 4. 確認無誤再實際套用
chezmoi apply --verbose
```

> ⚠️ 在 mac 工作機上若 profile 選 `workstation`,步驟 4 會實際安裝套件。
> 建議先在拋棄式的 Debian VM / 容器選 `vm` / `container` 試,或全程只用 `--dry-run`。

`vm` / `container` apply 後,`40-wire-shell-rc` 會把 `source ~/.config/shell/env.sh`
串進 `~/.bashrc` / `~/.zshrc`,**開新 shell** 即可直接使用 mise 安裝的工具(免手動 export)。

## 套件分層

- **`system`**(`.chezmoidata.yaml` → `10-install-system-packages`):各平台套件管理器都穩定提供的
  基礎工具(git / zsh / curl / fzf / jq / ripgrep / bat / fd),mac 用 brew、Debian 用 apt。
- **`mise`**(`20-install-mise-tools`):分兩層宣告(`.chezmoidata.yaml` → `packages.mise`)。
  - **`common`**(vm + workstation):runtime + 現代 CLI —— `eza` / `zoxide` / `delta` / `jless` /
    `node@lts` / `go` / `uv`。
  - **`workstation`**(僅 mac):由 Brewfile 遷入的開發向 CLI —— `neovim` / `helix` / `zellij` /
    `tree-sitter` / `ast-grep` / `typos-cli` / `glab` / `fastfetch` / `lazygit` / `lazydocker` /
    `btop` / `direnv` / `gh`。
  改由 [mise](https://mise.jdx.dev) 安裝預編譯 binary,以在較舊的 Debian(如 bullseye,apt 缺
  或過舊)也能取得一致版本,並可 `mise outdated` / `upgrade` 追蹤版本。mise 工具透過
  **shims 目錄上 PATH** 暴露(見 `env.sh`),不用 `mise activate`。

## 驗證狀態(誠實標註)

- **`vm` profile:已在真實 Debian 13 (trixie) arm64 端到端實跑通過** —— apt 安裝、
  fd/bat symlink、mise 裝預編譯 binary、shims 上 PATH、rc 串接皆驗證,`eza`/`zoxide`/`delta` 可執行。
- **可攜別名/history 與 gitconfig 核心:目前僅本機 render 驗證**(三 profile `chezmoi cat` 渲染正確、
  `.gitconfig` 僅 vm 部署、env.sh 經 `bash -n`/`zsh -n` 語法檢查通過),**尚未在 VM 開新 shell 端到端實跑**——
  待下次 VM `chezmoi apply` 後確認 `type ls cat rg`、`git lg`、`git config core.pager` 再回填此處。
- **tmux(設定 + 安裝腳本):已在真實 Debian VM `chezmoi apply` 端到端實跑** —— 套用成功、
  `command -v tmux` 可執行、`~/.tmux/plugins` 外掛(tpm/sensible/resurrect/continuum)齊全;
  本機另以 `chezmoi cat` 三 profile render(僅 vm 部署)+ 安裝腳本 `sh -n` 驗證。
  (OSC52 複製、Catppuccin 主題、Alt 快捷鍵屬互動操作,日常使用中,未逐項自動化驗證。)
- `container` / `workstation` profile:目前僅到 render / dry-run 層級,**尚未在各自的真實目標實跑**。

## 已知限制 / 待辦

- **jless 無 linux/arm64 預編譯 binary**:mise(aqua registry)僅支援 `linux/amd64` 與 `darwin`。
  `20-install-mise-tools` 已用 `.chezmoi.arch` 在 `linux/arm64` 把 jless 從清單剔除(其餘照裝);
  該平台的 JSON 檢視以 apt 的 `jq` 替代。amd64 Linux 與 macOS 仍正常安裝 jless。
- **fd / bat 名稱差異**:Debian 執行檔為 `fdfind` / `batcat`,`10-install-system-packages` 會在
  `~/.local/bin` 建立 `fd` / `bat` symlink;`env.sh` 已把該路徑加上 PATH。
- **應用層尚未完成**:`30-install-app-tools` 目前只裝 `leaf`;`markitdown`(Python)、
  `defuddle`(Node)留為 TODO,需先用 mise 備妥 runtime。
- **VM 的 shell/git 設定是裁切版,非整份照搬**:mac 的 `zsh/.zshrc` 與 mac/Homebrew 深度耦合
  (zinit 走 `$HOMEBREW_PREFIX`、p10k 需 Nerd Font、寫死的 `/Users/...` 與 `/opt/homebrew/...` PATH),
  整份套到 VM 會大量報錯。故只移植「可攜層」:`env.sh` 帶工具別名(`command -v` 守衛,工具不在時退回原生)
  與 history(分 bash/zsh);`dot_gitconfig.tmpl` 帶 alias/delta pager,git 身分(name/email)於
  `chezmoi init` 時以 `promptStringOnce` 詢問(僅 vm 詢問、可留空 → 不寫入該欄位),**刻意捨棄**
  sourcetree、`core.editor=nvim`(改用 git 預設)、delta `chameleon` 主題(主題檔未受管)。機制/主題層續留 workstation stow。
- **VM 的 tmux 是 Linux 裁切版**:以 stow 的 `tmux/.config/tmux/tmux.conf` 為基礎,但 macOS 專用的
  `copy-pipe-and-cancel "pbcopy"` 在 Linux 是死綁定,故改用 `set -g set-clipboard on`(OSC52,經終端機
  回傳本機剪貼簿,SSH/headless 適用)+ `copy-selection-and-cancel`,並**移除依賴 xclip 的 tmux-yank 外掛**;
  其餘(prefix、Alt 快捷鍵、Catppuccin 主題、resurrect/continuum)照搬。tmux 本體與 TPM 由 vm-gated 的
  `50-setup-tmux` 以 apt + `git clone` + `install_plugins` 備妥(**刻意不進 `.chezmoidata.yaml`**,避免裝到
  container)。workstation/mac 的 tmux 仍走 stow 原版(pbcopy),與 chezmoi 並存。
- **tmux 首次啟動會顯示 `Tmux resurrect file not found`**:這是 `@continuum-restore 'on'` 在尚無存檔時
  叫 resurrect 還原所致,屬一次性提示、無害;首次自動或手動(`prefix + Ctrl-s`)存檔後即消失。維持現狀不改設定。
- **workstation 的 shell rc 不由 chezmoi 串接**:mac 的 `.zshrc` 由 stow 管理,
  `40-wire-shell-rc` 刻意略過 workstation,避免與 stow 衝突;其 PATH 由既有 `.zshrc` 自理。
- **與現有 stow / Brewfile 的關係**:目前各自獨立。若未來決定全面轉 chezmoi,
  再把現有 dotfile 以 `chezmoi add` 逐步納入並 template 化。
- **Brewfile / `.zshrc` 去重屬後續(尚未執行)**:`mise` 的 `workstation` tier 已宣告 neovim/helix/
  zellij/lazygit… 等(原本由 `Brewfile` 安裝),但 mac 目前仍以 `install.sh` + `Brewfile` 為實際安裝
  路徑,故**尚未從 Brewfile 移除**,以免重複/破壞現行流程。待 chezmoi 接手 mac 編排時,再一併:
  ① 從 `Brewfile` 移除已遷入 mise 的工具;② 移除 `asdf`(mise 取代,並清掉 `zsh/.zshrc` L149 的 asdf
  shims PATH);③ 評估 rust 由 rustup(`.zshrc` L151-152)改 mise。「需查證」CLI(tldr→tealdeer、
  jc/speedtest 走 pipx、kanata 需驅動、agent-browser)先留 brew,逐個確認 backend 後再搬。
```
