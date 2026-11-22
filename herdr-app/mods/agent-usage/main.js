// 各 agent 的用量額度，一行顯示，例如「Claude 5h 51% 1h13m 7d 15% 5d6h」（% 後面是距離重置的時間）。
// 資料由每台機器上的 herdr-usage 存在 ~/.cache/herdr-usage/<agent>.json：
//   { "name": "Claude", "at": <epoch 秒>, "limits": [{ "label", "used", "resets_at" }] }
// 這個 mod 只讀檔，不查詢任何服務。同一個 agent 在多台機器都有資料時取最新的。
// 來源：這台電腦、每台已連線的機器，以及（Windows 上）預設的 WSL 發行版。

import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme, exec, machines, window } from "herdr";

// 先請 herdr-usage 更新 Codex 這類沒有掛接點的來源，再讀檔。沒裝 herdr-usage 也照樣讀。
const READ = '"$HOME/.local/bin/herdr-usage" refresh >/dev/null 2>&1; cat "${XDG_CACHE_HOME:-$HOME/.cache}"/herdr-usage/*.json 2>/dev/null';
const STALE_MINUTES = 60;
// 用量的三個顏色寫死，不取主題的 ansi 色：nord 的綠（#a3be8c）和紅（#bf616a）偏灰，
// 在狀態列的小字上不夠醒目。
const GREEN = "#7ee787", YELLOW = "#f2cc60", RED = "#ff7b72";

function parse(stdout) {
  const out = [];
  for (const line of (stdout ?? "").split("\n")) {
    try {
      const x = JSON.parse(line);
      if (x?.name && Array.isArray(x.limits) && x.limits.length) out.push(x);
    } catch { /* 空行或壞掉的檔案：略過 */ }
  }
  return out;
}

// 一台機器（null：這台電腦）上存的所有 agent。讀不到就當作沒有。
async function readFrom(machine) {
  const r = await exec("sh", ["-c", READ], machine ? { on: machine, timeout: 5000 } : { timeout: 5000 }).catch(() => null);
  const found = parse(r?.stdout);
  if (found.length || machine || window()?.platform !== "windows") return found;
  // 這台電腦是 Windows、agent 跑在 WSL（在 PowerShell 分頁裡進 wsl，沒有把 WSL 加成機器）：
  // 直接請預設的 WSL 發行版印出存檔。參數刻意不含引號和 $，避免 Windows 的引號規則。
  const w = await exec("wsl.exe", ["--cd", "~", "-e", ".local/bin/herdr-usage", "dump"], { timeout: 15000 }).catch(() => null);
  return parse(w?.stdout);
}

// 距離重置還有多久："13m"、"1h13m"、"5d6h"。
function left(seconds) {
  const s = Math.floor(seconds);
  if (s < 3600) return `${Math.max(1, Math.floor(s / 60))}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h${String(Math.floor((s % 3600) / 60)).padStart(2, "0")}m`;
  return `${Math.floor(s / 86400)}d${Math.floor((s % 86400) / 3600)}h`;
}

function age(seconds) {
  const m = Math.floor(seconds / 60);
  return m < STALE_MINUTES ? null : m < 1440 ? `${Math.floor(m / 60)}h ago` : `${Math.floor(m / 1440)}d ago`;
}

export default class AgentUsage extends View {
  init(_props, cx) {
    this.agents = [];
    cx.spawn(async (cx) => {
      for (;;) {
        await this.load();
        cx.notify();
        await cx.sleep(30000);
      }
    });
  }

  async load() {
    const remote = (machines() ?? []).filter((m) => m.name && m.layout === "ready").map((m) => m.name);
    const all = (await Promise.all([null, ...remote].map(readFrom))).flat();
    const newest = {};
    for (const a of all) if (!newest[a.name] || (a.at ?? 0) > (newest[a.name].at ?? 0)) newest[a.name] = a;
    this.agents = Object.values(newest).sort((a, b) => a.name.localeCompare(b.name));
  }

  render() {
    const t = theme();
    const now = Date.now() / 1000;
    const color = (used) => (used >= 80 ? RED : used >= 50 ? YELLOW : GREEN);
    return h_flex().size_full().px(14).gap(14).items_center().justify_end()
      .bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8)
      .children(this.agents.map((a) => {
        const old = age(now - (a.at ?? now));
        return h_flex().flex_none().gap(6).items_center()
          .child(div().text_color(t.foreground).child(a.name))
          .children(a.limits.map((l) => {
            // 重置時間已過的額度視為 0%，不顯示倒數。
            const reset = l.resets_at != null && l.resets_at <= now;
            const used = reset ? 0 : Math.round(l.used ?? 0);
            return h_flex().flex_none().gap(3).items_center()
              .child(div().text_color(t.muted).child(l.label))
              .child(div().text_color(color(used)).child(`${used}%`))
              .when(!reset && l.resets_at != null, (el) => el.child(div().text_color(t.muted).child(left(l.resets_at - now))));
          }))
          .when(Boolean(old), (el) => el.child(div().text_color(t.muted).child(`(${old})`)));
      }));
  }
}
