#!/bin/sh
# VM bootstrap 選單:選 profile → 檢查/安裝 chezmoi → init(互動問 git)→ dry-run → 確認 → apply。
# 用法:在乾淨 VM clone 本專案後,於 repo 根執行 ./bootstrap.sh
# 純 POSIX sh、零依賴(只需 git + shell + curl),適合尚未裝任何工具的環境。
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)   # 腳本所在 = repo 根

# 1. profile 選單(目前僅 vm 可選,其餘標示尚未開放)
echo "選擇環境 profile:"
echo "  1) vm           — Debian 測試 VM"
echo "  2) container    — (尚未開放)"
echo "  3) workstation  — (尚未開放)"
printf "輸入選項 [1]: "; read -r choice
case "${choice:-1}" in
  1) PROFILE="vm" ;;
  2|3) echo "該 profile 尚未開放,結束。"; exit 0 ;;
  *) echo "無效選項,結束。"; exit 1 ;;
esac

# 2. profile 專屬細部選項(vm 目前無;未來其他 profile 在此各自擴充)
case "$PROFILE" in
  vm) : ;;
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
  --promptString "環境 profile (container/vm/workstation)=$PROFILE"

# 5. dry-run 預覽 → 確認 → 實際 apply
echo "== 預覽(dry-run,不會實際變更)=="
"$CHEZMOI" apply --source "$REPO_DIR" --dry-run --verbose
printf "以上為將套用的變更,確認要實際 apply 嗎? [y/N]: "; read -r go
case "$go" in
  [Yy]*)
    "$CHEZMOI" apply --source "$REPO_DIR" --verbose
    echo "完成。開新 shell 即可使用(mise 工具 / 別名 / tmux)。"
    ;;
  *) echo "已取消 apply。可稍後手動執行:$CHEZMOI apply --source $REPO_DIR" ;;
esac
