# chezmoi 跨平台環境初始化(最小骨架)

用 [chezmoi](https://chezmoi.io) 的 **profile + template** 機制,在 macOS / Debian VM / 容器
等不同環境中,以同一份 source 部署「對應子集」的工具與設定。

這是一份**獨立試驗骨架**,放在 `dotfiles/chezmoi/`,不影響現有的 stow 結構。

## 三層 profile

| profile | 對應場景 | 部署內容 |
|---|---|---|
| `container` | docker / podman 用完即丟 | 僅 `system` 基礎套件 |
| `vm` | Debian 測試 VM | `system` + `mise` 現代 CLI/runtime |
| `workstation` | mac m4 工作機 | 全部,含 nvim 設定與應用層工具(leaf 等) |

profile 在 `chezmoi init` 時詢問一次(見 `.chezmoi.toml.tmpl`),之後所有
template / `.chezmoiignore` / 安裝腳本都依 `.profile` 分支。

## 檔案結構

```
chezmoi/
├── .chezmoi.toml.tmpl                         # init 時詢問 profile
├── .chezmoidata.yaml                          # 套件清單 + 跨平台名稱映射(宣告層)
├── .chezmoiignore                             # 非 workstation 排除 .config/nvim
├── dot_config/
│   ├── nvim/init.lua                          # workstation-only(其餘 profile 被忽略)
│   └── shell/env.sh.tmpl                      # 共通,展示 OS/profile 條件 template
├── run_onchange_before_10-install-system-packages.sh.tmpl   # 全 profile:apt/brew 基礎套件
├── run_onchange_before_20-install-mise-tools.sh.tmpl        # vm/workstation:mise + 現代 CLI
└── run_onchange_after_30-install-app-tools.sh.tmpl          # workstation:leaf 等應用層
```

## 試用(務必先 dry-run)

```sh
# 1. 安裝 chezmoi
#    mac:  brew install chezmoi
#    其他: sh -c "$(curl -fsSL get.chezmoi.io)"

# 2. 以本目錄為 source 初始化(會詢問 profile,只生成 config,預設不套用)
chezmoi init --source="$HOME/dotfiles/chezmoi"

# 3. 預覽會做什麼(強烈建議先看)
chezmoi apply --dry-run --verbose

# 4. 確認無誤再實際套用
chezmoi apply --verbose
```

> ⚠️ 在 mac 工作機上若 profile 選 `workstation`,步驟 4 會實際安裝套件。
> 建議先在拋棄式的 Debian VM / 容器選 `vm` / `container` 試,或全程只用 `--dry-run`。

## 已知限制 / 待辦

- **Debian 11 apt 缺套件**:`eza`、`zoxide`、`delta`、`jless` 在 bullseye 的 apt
  沒有(或過舊),因此改由 `mise` 安裝預編譯 binary。這是 `system` 與 `mise`
  兩層的分界依據——若你之後只跑 Debian 12/13,部分工具可考慮移回 apt。
- **fd / bat 名稱差異**:Debian 執行檔為 `fdfind` / `batcat`,安裝腳本會在
  `~/.local/bin` 建立 `fd` / `bat` symlink,需確保該路徑在 PATH(`env.sh` 已處理)。
- **應用層尚未完成**:`run_..._30-install-app-tools` 目前只裝 `leaf`;
  `markitdown`(Python)、`defuddle`(Node)留為 TODO,需先用 mise 備妥 runtime。
- **與現有 stow / Brewfile 的關係**:目前各自獨立。若未來決定全面轉 chezmoi,
  再把現有 dotfile 以 `chezmoi add` 逐步納入並 template 化。
