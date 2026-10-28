#!/bin/sh
# VM bootstrap 選單:選 profile → 檢查/安裝 chezmoi → init(互動問 git)→ dry-run → 確認 → apply。
# 用法:在乾淨 VM clone 本專案後,於 repo 根執行 ./bootstrap.sh
# 純 POSIX sh、零依賴(只需 git + shell + curl),適合尚未裝任何工具的環境。
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)   # 腳本所在 = repo 根

# 1. profile 選單(vm / wsl 可選,其餘標示尚未開放)。
#    在 WSL 內(/proc/version 含 microsoft)預選 wsl,其餘預選 vm。
DEFAULT_CHOICE=1
if grep -qi microsoft /proc/version 2>/dev/null; then DEFAULT_CHOICE=2; fi
echo "選擇環境 profile:"
echo "  1) vm           — Debian 測試 VM(基本 CLI)"
echo "  2) wsl          — Windows WSL Debian(完整開發環境:nvim / zsh / zellij …,需 sudo)"
echo "  3) container    — (尚未開放)"
echo "  4) workstation  — (尚未開放)"
printf "輸入選項 [%s]: " "$DEFAULT_CHOICE"; read -r choice
case "${choice:-$DEFAULT_CHOICE}" in
  1) PROFILE="vm" ;;
  2) PROFILE="wsl" ;;
  3|4) echo "該 profile 尚未開放,結束。"; exit 0 ;;
  *) echo "無效選項,結束。"; exit 1 ;;
esac

# 2. profile 專屬細部選項(目前皆無;未來各 profile 在此各自擴充)
case "$PROFILE" in
  vm|wsl) : ;;
esac

# 3. 檢查 chezmoi,缺則詢問是否安裝
if command -v chezmoi >/dev/null 2>&1; then
  CHEZMOI=$(command -v chezmoi)
elif [ -x "$HOME/.local/bin/chezmoi" ]; then
  CHEZMOI="$HOME/.local/bin/chezmoi"
else
  printf "未偵測到 chezmoi,要安裝嗎? [y/N]: "; read -r ans
  case "$ans" in
    [Yy]*)
      if ! command -v curl >/dev/null 2>&1; then
        echo "找不到 curl,無法下載 chezmoi 安裝程式。" >&2
        echo "請先安裝 curl(Debian: sudo apt-get update && sudo apt-get install -y curl)後重跑本腳本。" >&2
        exit 1
      fi
      mkdir -p "$HOME/.local/bin"
      sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin"
      CHEZMOI="$HOME/.local/bin/chezmoi"
      ;;
    *) echo "未安裝 chezmoi,結束。"; exit 0 ;;
  esac
fi

# 4. init:預填 profile(選單已選),git name/email 不預填 → chezmoi 仍會互動詢問。
#    --promptString 依 prompt「文字」比對,須與 chezmoi/.chezmoi.toml.tmpl 內的字串一致;
#    若該 prompt 文字改動,請同步更新下面這行。
"$CHEZMOI" init --source "$REPO_DIR" \
  --promptString "環境 profile (container/vm/wsl/workstation)=$PROFILE"

# 把關:init 後實際生效的 profile 必須等於選單所選(既有 config 曾讓舊值蓋過選單,靜默套錯 profile)。
EFFECTIVE=$("$CHEZMOI" execute-template --source "$REPO_DIR" '{{ .profile }}' 2>/dev/null || true)
if [ "$EFFECTIVE" != "$PROFILE" ]; then
  echo "chezmoi 設定檔生效的 profile 為「$EFFECTIVE」,與選單所選「$PROFILE」不符。" >&2
  echo "請檢查 ~/.config/chezmoi/chezmoi.toml(或刪除後重跑本腳本)。" >&2
  exit 1
fi
echo "profile: $PROFILE"

# 收尾摘要:apply 後統一列出「需 root 而本次未安裝」的項目。
# 放這裡而非各 run_ 腳本內的理由:
#   1. 腳本的略過訊息會被埋在 apply 中段,使用者容易錯過。
#   2. 10-install-system-packages 是 run_onchange_,重跑時不會再執行;
#      唯有在此檢查「實際狀態」才能每次都如實反映仍缺什麼。
report_missing_root_packages() {
    # 需 root 的項目 = packages.system(從 .chezmoidata.yaml 取,避免兩處各寫一份)
    #                  + wsl 的 packages.apt_wsl
    #                  + tmux(50-setup-tmux 專屬,刻意不列入 .chezmoidata.yaml)
    # apt 套件名多與命令名相同(git/zsh/curl/tmux…);例外在下方 case 對應(build-essential → gcc)。
    need=$("$CHEZMOI" execute-template --source "$REPO_DIR" \
        '{{ range .packages.system }}{{ .apt }} {{ end }}{{ if eq .profile "wsl" }}{{ range .packages.apt_wsl }}{{ . }} {{ end }}{{ end }}' 2>/dev/null || true)
    need="$need tmux"

    missing=""
    for pkg in $need; do
        case "$pkg" in
            build-essential) cmd=gcc ;;
            *) cmd=$pkg ;;
        esac
        command -v "$cmd" >/dev/null 2>&1 || missing="$missing $pkg"
    done
    [ -n "$missing" ] || return 0

    echo
    echo "────────────────────────────────────────────────────────────"
    echo " ⚠ 下列項目需 root 權限,本次未安裝:$missing"
    echo
    echo "   取得 root/sudo 後執行:"
    echo "     sudo apt-get update && sudo apt-get install -y$missing"
    echo
    echo "   完成後重跑 ./bootstrap.sh,tmux 外掛(TPM)會自動補裝。"
    echo "────────────────────────────────────────────────────────────"
}

# 5. dry-run 預覽 → 確認 → 實際 apply
echo "== 預覽(dry-run,不會實際變更)=="
"$CHEZMOI" apply --source "$REPO_DIR" --dry-run --verbose
printf "以上為將套用的變更,確認要實際 apply 嗎? [y/N]: "; read -r go
case "$go" in
  [Yy]*)
    "$CHEZMOI" apply --source "$REPO_DIR" --verbose
    echo "完成。開新 shell 即可使用(mise 工具 / 別名)。"
    [ "$PROFILE" = "wsl" ] && echo "wsl:登入 shell 已切為 zsh(若 chsh 成功),請關閉終端機重開;首次進 zsh 會由 zinit 下載外掛。"
    report_missing_root_packages
    ;;
  *) echo "已取消 apply。可稍後手動執行:$CHEZMOI apply --source $REPO_DIR" ;;
esac
