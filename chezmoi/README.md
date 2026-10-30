# chezmoi 跨平台環境初始化(最小骨架)

用 [chezmoi](https://chezmoi.io) 的 **profile + template** 機制,在 macOS / Debian VM / 容器
等不同環境中,以同一份 source 部署「對應子集」的工具與設定。

這是一份**獨立試驗骨架**,放在 `dotfiles/chezmoi/`,不影響現有的 stow 結構。

## 四層 profile

| profile | 對應場景 | 部署內容 |
|---|---|---|
| `container` | docker / podman 用完即丟 | 僅 `system` 基礎套件 |
| `vm` | Debian 測試 VM | `system` + `mise` 現代 CLI/runtime,把工具串進 shell rc,並部署可攜別名(含 git 縮寫)/history/zoxide、gitconfig 核心與 tmux(含 TPM 外掛) |
| `wsl` | Windows 公司機的 WSL Debian 13(日常開發) | **`vm` 的全部**(獨立可跑,不需先套 vm)+ apt 開發依賴(zsh / build-essential / unzip / wget / rsync)+ `mise` 的 wsl tier 開發向 CLI(nvim / zellij / lazygit / gh / glab…)+ zsh 全套(zinit / p10k / OMZ / fzf 整合)+ nvim 設定(external clone dot-nvim,PHP 關閉)+ zellij 設定(含 zjstatus)+ bat / delta 主題 + Windows 側 Alacritty / WezTerm 設定、字型、win32yank |
| `workstation` | mac m4 工作機 | 全部,含應用層工具(leaf 等),以及 `mise` 的 workstation tier 開發向 CLI(尚未啟用) |

profile 在 `chezmoi init` 時詢問一次(見 `.chezmoi.toml.tmpl`;在 WSL 內預選 `wsl`,其餘預選 `vm`),
之後所有 template / `.chezmoiignore` / 安裝腳本都依 `.profile` 分支。

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
    ├── .chezmoiignore                         # 依 profile 排除:gitconfig/tmux 僅 vm+wsl;zsh/bat/delta/language-support 僅 wsl;windows/ 不部署
    ├── .chezmoiexternal.toml.tmpl             # wsl-only:~/.config/nvim ← git clone HJayWei/dot-nvim(與 stow submodule 同源)
    ├── dot_gitconfig.tmpl                     # vm/wsl;可攜核心(identity/alias/delta pager);wsl 另 include delta 主題 + editor=nvim
    ├── dot_zshrc.tmpl                         # wsl-only;自 mac zsh/.zshrc 移植(zinit/p10k/OMZ/外掛/fzf),別名等交給 env.sh
    ├── dot_p10k.zsh.tmpl                      # wsl-only;{{ include "../zsh/.p10k.zsh" }} 指回 stow 原檔
    ├── dot_language-support                   # wsl-only;覆寫 dot-nvim 預設(PHP/RUST=false)
    ├── dot_config/
    │   ├── shell/env.sh.tmpl                  # 共通;PATH + 可攜別名(含 git 縮寫)+ history + zoxide(cd=z)
    │   ├── tmux/tmux.conf.tmpl                # vm/wsl;Linux 可攜版(OSC52 剪貼簿,TPM 外掛)
    │   ├── fzf-git/fzf-git.sh.tmpl            # wsl-only;include 指回 zsh/.config/fzf-git
    │   ├── bat/themes/Dracula.tmTheme.tmpl    # wsl-only;include 指回 bat/.config
    │   ├── delta/themes.gitconfig.tmpl        # wsl-only;include 指回 git/.config/delta
    │   └── zellij/                            # wsl-only;config.kdl(include + pbcopy→win32yank)、layouts(含 default.kdl symlink)、zjstatus.wasm
    ├── windows/                               # Windows 側設定來源(不部署到 ~;由 80-sync-windows 複製到 Windows 家目錄)
    │   ├── alacritty.toml                     # %APPDATA%\alacritty\alacritty.toml;自 mac 版移植,shell=wsl.exe,Wombat 內嵌
    │   └── wezterm.lua                        # %USERPROFILE%\.config\wezterm\wezterm.lua;暗色透明,Wombat,fonts/ 免安裝字型
    ├── run_onchange_before_10-install-system-packages.sh.tmpl   # 全 profile:apt/brew 基礎套件;wsl 附加 apt_wsl
    ├── run_onchange_before_20-install-mise-tools.sh.tmpl        # vm/wsl/workstation:mise + 現代 CLI(各 tier)
    ├── run_onchange_after_30-install-app-tools.sh.tmpl          # workstation:leaf 等應用層
    ├── run_onchange_after_40-wire-shell-rc.sh.tmpl              # 非 workstation:把 env.sh 串進 shell rc(wsl 只串 .bashrc)
    ├── run_after_50-setup-tmux.sh.tmpl                          # vm/wsl:apt 裝 tmux + clone TPM + 裝外掛(每次 apply,冪等 guard)
    ├── run_after_60-setup-zsh.sh.tmpl                           # wsl:clone zinit + chsh 切 zsh(每次 apply,冪等 guard)
    ├── run_onchange_after_70-build-bat-cache.sh.tmpl            # wsl:bat cache --build(主題檔 hash 變才重跑)
    └── run_onchange_after_80-sync-windows.sh.tmpl               # wsl:複製 Alacritty/WezTerm 設定到 Windows、下載字型、裝 win32yank
```

## VM 快速開始(一支選單腳本)

乾淨 VM 上最省事的方式:clone 後跑 repo 根的 `bootstrap.sh`——它把「選 profile →
檢查/詢問安裝 chezmoi → `chezmoi init`(互動詢問 git name/email)→ dry-run 預覽 →
確認 → apply → 收尾摘要」包成一條互動流程,零依賴(只需 git + shell + curl)。

收尾摘要會在最後統一列出「需 root 而本次未安裝」的項目(如無 sudo 時的 `tmux`)
與補裝指令,免得略過訊息被埋在 apply 中段而錯過;全部裝齊時則不印任何東西。
它檢查的是**實際狀態**(`command -v`)而非腳本回報,故重跑時仍能如實反映還缺什麼。

```sh
git clone https://github.com/HJayWei/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh        # 選 1) vm 或 2) wsl(WSL 內預選 2);沒裝 chezmoi 會問你要不要裝;最後 dry-run 確認才 apply
```

> 目前選單開放 `vm` 與 `wsl`;`container` / `workstation` 標示為尚未開放。
> `wsl` 需 sudo(apt 裝 zsh / build-essential 等);apply 中 `chsh` 會要求輸入密碼,
> 完成後關閉終端機重開即進 zsh,首次啟動由 zinit 下載外掛。
> 想手動逐步操作、或在其他平台,見下方「試用」。

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

- **`system`**(`.chezmoidata.yaml` → `10-install-system-packages`):bootstrap 的前置工具
  (git / curl),需 root(apt)才能裝。兩者實務上必然已存在——沒有 git 無法 clone 專案、
  沒有 curl 抓不到 chezmoi/mise,**根本跑不到這步**——故本層對 vm/workstation 是 no-op,
  留著僅為 container(極簡 image 可能真的缺)的安全網。
  **非 root 且無 sudo 時,`10-install-system-packages` 會 fail-loud 印訊息並跳過本層**
  (不讓 apt 直接噴 lock 權限錯誤),其餘 CLI 一律由 mise 提供,故無權限使用者仍能裝齊現代工具。
  (`zsh` 曾列於本層,已移除:vm 用 bash 且 `apt install zsh` 不會建立 `~/.zshrc`,
  `40-wire-shell-rc` 因而不會串接,裝了等於裸 zsh;mac 用系統內建 zsh + Brewfile 的 zinit,
  從未裝過 brew 版 zsh。三個 profile 皆無需求。)
- **`mise`**(`20-install-mise-tools`):分兩層宣告(`.chezmoidata.yaml` → `packages.mise`)。
  - **`common`**(vm + workstation):runtime + 現代 CLI —— `eza` / `bat` / `fd` / `ripgrep` / `jq` /
    `zoxide` / `fzf` / `delta` / `jless` / `node@lts` / `go` / `uv`。(`bat`/`fd`/`ripgrep`/`jq` 原在
    `system`/apt,為支援無 sudo 使用者改由 mise 供應——順帶免去 Debian `batcat`/`fdfind` 的 symlink;
    `fzf` 則因 bullseye 的 0.24 太舊、缺 zoxide 互動選單所需的新 `--preview-window` 選項而報錯,同樣改用 mise。)
  - **`workstation`**(僅 mac):由 Brewfile 遷入的開發向 CLI —— `neovim` / `helix` / `zellij` /
    `tree-sitter` / `ast-grep` / `typos-cli` / `glab` / `fastfetch` / `lazygit` / `lazydocker` /
    `btop` / `direnv` / `gh`。
  - **`wsl`**(僅 wsl):neovim / zellij / tree-sitter / ast-grep / typos / lazygit / btop / direnv / gh / glab /
    fastfetch / jc / rust。名稱皆以 `mise registry` 查證(registry 名為 `typos`,非 `typos-cli`)。與 workstation 重疊
    但刻意獨立成列,待 workstation 啟用時再抽共用層。
  - **`apt_wsl`**(僅 wsl,走 `10-install-system-packages`,需 sudo):zsh / build-essential(treesitter 編譯)/ unzip(mason 解壓)/ wget / rsync。
    (`rsync.nvim` 的 build 是 `cargo build`,故 wsl 的 mise tier 含 `rust`,`.language-support` 的 `RUST` / `RSYNC` 皆開。)
  改由 [mise](https://mise.jdx.dev) 安裝預編譯 binary,以在較舊的 Debian(如 bullseye,apt 缺
  或過舊)也能取得一致版本,並可 `mise outdated` / `upgrade` 追蹤版本。mise 工具透過
  **shims 目錄上 PATH** 暴露(見 `env.sh`),不用 `mise activate`。

## 驗證狀態(誠實標註)

- **`vm` profile:已在真實 Debian 13 (trixie) arm64 端到端實跑通過** —— apt 安裝、
  mise 裝預編譯 binary、shims 上 PATH、rc 串接皆驗證,`eza`/`zoxide`/`delta` 可執行。
  (註:該次實跑為舊分層;`bat`/`fd`/`ripgrep`/`jq` 改由 mise 供應與「無 sudo 跳過 apt」屬新變更,
  已另在無權限 VM 實跑驗證——見下方已知限制。)
- **可攜別名(含 git 縮寫)/history/zoxide、mise common runtime(go/uv/fzf)與 gitconfig 核心:
  已在 VM `chezmoi apply` 後開新 shell 端到端確認** —— 別名與 `g` / `gst` / `g lg` 生效、`cd` 具 zoxide
  frecency 跳轉(`fzf` 改由 mise 供應後不再報 `invalid preview window option`)、`go` / `uv` / `fzf`
  經 `mise ls` 確認安裝;本機另以三 profile `chezmoi cat` render + `bash -n` / `zsh -n` / `sh -n` 把關。
- **tmux(設定 + 安裝腳本):已在真實 Debian VM `chezmoi apply` 端到端實跑** —— 套用成功、
  `command -v tmux` 可執行、`~/.tmux/plugins` 外掛(tpm/sensible/resurrect/continuum)齊全;
  本機另以 `chezmoi cat` 三 profile render(僅 vm 部署)+ 安裝腳本 `sh -n` 驗證。
  (OSC52 複製、Catppuccin 主題、Alt 快捷鍵屬互動操作,日常使用中,未逐項自動化驗證。)
- **`bootstrap.sh`(VM 入口選單):已在 VM 實際使用確認** —— 目前 VM 都透過它執行(選 profile →
  檢查/安裝 chezmoi → `init` 問 git → dry-run → 確認 → apply),整段流程無誤。
  (收尾摘要已在真實無權限 VM 確認顯示;本機另以假造 PATH 實跑函式驗證「缺 tmux 時列出補裝指令」
  與「全裝齊時不印任何東西」兩情境。)
- **`wsl` profile:僅到本機 render 層級,尚未在真實 WSL 實跑**(2026-10-23)。已驗證:四 profile 以 `chezmoi archive` +
  `execute-template` render,`vm` / `container` / `workstation` 的輸出與變更前 byte-for-byte 相同(僅 workstation 少了從未部署過的
  nvim 佔位檔);以假造 `.chezmoi.os=linux` render 的 `10` / `20` 腳本,wsl 相對 vm 只多 apt_wsl 與 mise wsl tier;所有渲染腳本
  `sh -n`、`.zshrc` / `.p10k.zsh` `zsh -n`、`.gitconfig` `git config --list`、`alacritty.toml` TOML parse、`wezterm.lua` 與 dot-nvim
  兩支 Lua `loadfile` 皆通過;`include` 的 4 個檔與 stow 原檔 `cmp` 一致;`dot-nvim` 的 `~/.language-support` 優先序以假 HOME 實測
  (無覆寫 → php/rust=true;有覆寫 → false)。**待 WSL 實測**:apt / mise 實裝、zinit 首次載入與 p10k 字型、`chsh`、external clone、
  mason 不再嘗試裝 PHP 工具、rust-analyzer 與 rsync.nvim 的 cargo build 成功、win32yank 剪貼簿、Alacritty / WezTerm 讀到複製過去的設定與 fonts/、zoxide `_ZO_DOCTOR` 是否警告。
- `container` / `workstation` profile:目前僅到 render / dry-run 層級,**尚未在各自的真實目標實跑**。

## 已知限制 / 待辦

- **wsl 依賴 dot-nvim 的三處修改,需先 push 到 GitHub `main` 才生效**:`.chezmoiexternal` 從 GitHub clone,不是用本 repo 的 submodule 工作樹。
  修改為:① `lua/utils/language-support.lua` 改為 `~/.language-support` 優先(mac 無該檔,行為不變);② `lua/config/options.lua`
  `vim.opt.shell` 改為「zsh 存在才設」;③ 同檔在 `has("wsl")` 且找到 `win32yank.exe` 時設 `vim.g.clipboard`。未 push 前 WSL 會拿到舊版,
  PHP 的 mason 工具仍會嘗試安裝。
- **Windows 側字型需手動一步(僅 Alacritty)**:WezTerm 以 `font_dirs` 從 `%USERPROFILE%\.config\wezterm\fonts` 直接載入,免安裝;
  Alacritty 只能用 Windows 已安裝字型,需到該目錄對 .ttf 右鍵「安裝」(使用者層級,不需管理者權限)。
- **workstation 的 nvim 佔位檔已移除**:`dot_config/nvim/init.lua`(3 行、從未實際部署)與 wsl 的 external 目標 `.config/nvim` 衝突
  (chezmoi 報 inconsistent state),故刪除;workstation 日後接手 nvim 時沿用同一個 external 即可。
- **`mise.workstation` 的 `typos-cli` 是錯名**(registry 為 `typos`),本次只在 wsl tier 用對的名字,workstation 列待其啟用時修。
- **jless 無 linux/arm64 預編譯 binary**:mise(aqua registry)僅支援 `linux/amd64` 與 `darwin`。
  `20-install-mise-tools` 已用 `.chezmoi.arch` 在 `linux/arm64` 把 jless 從清單剔除(其餘照裝);
  該平台的 JSON 檢視以 mise 的 `jq` 替代(`jq` 有 linux/arm64 binary)。amd64 Linux 與 macOS 仍正常安裝 jless。
- **無 sudo 路徑:主要部分已在真實無權限 VM(Debian / arm64)實跑驗證**:
  `10-install-system-packages` 與 `50-setup-tmux` 皆為「非 root 且無 sudo → 印訊息並 `exit 0` 跳過 apt」
  (tmux 無法裝時連 TPM 外掛一併跳過,因 `install_plugins` 需啟動 tmux server),兩支跳過時都會印手動指令。
  已驗證:`10` 的略過訊息如實印出;`bat`/`fd`/`ripgrep`/`jq` 改由 mise 供應後於 arm64 實裝
  **11/11 成功**(eza/bat/fd/ripgrep/jq/zoxide/fzf/delta/node/go/uv),`jless` 依 `.chezmoi.arch` 正確剔除;
  bootstrap 收尾摘要亦確認顯示。
  **尚未驗證**:`50-setup-tmux` 的無權限略過訊息,以及「手動裝 tmux → 重跑 `./bootstrap.sh` →
  TPM 自動補裝」的接續流程(該次實跑中兩支 tmux 腳本被一併誤刪,故未執行到)。
  重跑語意的差異:`50-setup-tmux` 特意用 `run_after_`(每次 apply 都跑、冪等 guard),上述接續流程才成立;
  `10-install-system-packages` 仍為 `run_onchange_`,但其內容對 vm 本就是 no-op,不依賴重跑。
- **應用層尚未完成**:`30-install-app-tools` 目前只裝 `leaf`;`markitdown`(Python)、
  `defuddle`(Node)留為 TODO,需先用 mise 備妥 runtime。
- **VM 的 shell/git 設定是裁切版,非整份照搬**:mac 的 `zsh/.zshrc` 與 mac/Homebrew 深度耦合
  (zinit 走 `$HOMEBREW_PREFIX`、p10k 需 Nerd Font、寫死的 `/Users/...` 與 `/opt/homebrew/...` PATH),
  整份套到 VM 會大量報錯。故只移植「可攜層」:`env.sh` 帶工具別名(`command -v` 守衛,工具不在時退回原生)、
  history(分 bash/zsh)、git 縮寫(精選對應 mac OMZ git 外掛常用子集:`g`/`gst`/`gco`/`gc`/`gcmsg`/`gp`/`gl`/`gd`…,
  跨 bash/zsh 的純 alias;`g`=git 搭配下方 gitconfig alias 即 `g lg` / `g st`),以及 zoxide 初始化
  (`zoxide init --cmd cd`,讓 `cd` 具 frecency 跳轉;`command -v` 守衛,container 無 zoxide 則跳過);
  `dot_gitconfig.tmpl` 帶 alias/delta pager,git 身分(name/email)於
  `chezmoi init` 時以 `promptStringOnce` 詢問(僅 vm 詢問、可留空 → 不寫入該欄位),**刻意捨棄**
  sourcetree、`core.editor=nvim`(改用 git 預設)、delta `chameleon` 主題(主題檔未受管),以及 mac 那層
  zinit/p10k/fzf 與整包 OMZ git 外掛(zsh-only、需 Nerd Font/網路)。機制/主題層續留 workstation stow。
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
- **`mise` workstation tier 的 backend 尚未實機查證**:`neovim` / `helix` / `zellij` / `tree-sitter` /
  `ast-grep` / `typos-cli` / `glab` / `fastfetch` / `lazygit` / `lazydocker` / `btop` / `direnv` / `gh`
  是依認知歸類(應有 aqua/ubi backend),**尚未實際安裝驗證**。待真的在 workstation 啟用時,逐個
  `mise registry | rg <tool>` 或 `mise use aqua:<owner>/<repo>` 確認;有出入再調整清單。
```
