#!/bin/sh
# 在 WSL 執行:同步 repo 的 herdr-app 設定與 Windows 端(scoop 的保留目錄,app 未安裝也可先放)。
#   herdr-app-sync.sh push          repo → Windows(80-sync-windows 呼叫);Windows 上改過的檔案略過並警告
#   herdr-app-sync.sh push --force  repo → Windows,一律以 repo 為準
#   herdr-app-sync.sh pull          Windows → repo,之後自行 git diff / commit
# 只處理 repo 裡已有的檔案;內建版面 / mods、執行狀態由 app 管理。
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")/../../herdr/.config/herdr-app" && pwd)
CMD=$(command -v cmd.exe || echo /mnt/c/Windows/System32/cmd.exe)
WIN_HOME=$(wslpath -u "$("$CMD" /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")
[ -d "$WIN_HOME" ] || { echo "==> [herdr-app] Windows 家目錄無法解析($WIN_HOME)。" >&2; exit 1; }
DST="$WIN_HOME/scoop/persist/herdr-app/data"

# Windows 上的內容若是 repo 曾經有過的版本,代表只是舊版,可以覆寫;否則是在 app 裡改過的。
edited_on_windows() {
    ! git -C "$SRC" cat-file -e "$(git -C "$SRC" hash-object --no-filters "$1")" 2>/dev/null
}

# app 會在 mods 資料夾產生 gpui-kit.d.ts / jsconfig.json,mac 連結時會出現在 repo 裡,不同步。
FILES=$(cd "$SRC" && find . -type f ! -name gpui-kit.d.ts ! -name jsconfig.json | sed 's#^\./##')

case "${1:-}" in
  push)
    for f in $FILES; do
        if [ -f "$DST/$f" ]; then
            cmp -s "$SRC/$f" "$DST/$f" && continue
            if [ "${2:-}" != "--force" ] && edited_on_windows "$DST/$f"; then
                echo "==> [herdr-app] 略過 $f:Windows 上有未同步回 repo 的修改。" >&2
                echo "    保留修改:$0 pull 後 commit;以 repo 為準:$0 push --force" >&2
                continue
            fi
        fi
        mkdir -p "$(dirname "$DST/$f")"
        cp "$SRC/$f" "$DST/$f"
        echo "    已同步: $DST/$f"
    done ;;
  pull)
    for f in $FILES; do
        if [ -f "$DST/$f" ] && ! cmp -s "$DST/$f" "$SRC/$f"; then
            # 舊版(repo 曾有過)不抄回來,否則會把 repo 較新的內容蓋掉。
            edited_on_windows "$DST/$f" || continue
            cat "$DST/$f" > "$SRC/$f"
            echo "    已取回: $f"
        fi
    done ;;
  *) echo "usage: $0 {push [--force]|pull}" >&2; exit 2 ;;
esac
