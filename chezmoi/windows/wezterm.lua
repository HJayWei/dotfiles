-- Windows 版 WezTerm 設定 — 由 dotfiles chezmoi(wsl profile)的 80-sync-windows 複製到
-- %USERPROFILE%\.config\wezterm\wezterm.lua(WezTerm 預設讀取位置之一,與 exe 放哪無關)。
-- 需求:暗色 + 透明背景;配色與 Alacritty 一致(Wombat);字型從同目錄 fonts/ 載入,免安裝。
local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- 開啟即進入 WSL(預設 distro)的家目錄
config.default_prog = { "wsl.exe", "--cd", "~" }

-- 字型:只從設定檔同目錄的 fonts/ 載入(80-sync-windows 下載 Maple Mono Normal NF CN 到此),
-- 不依賴 Windows 已安裝字型;找不到時退回 WezTerm 內建的 JetBrains Mono。
config.font_locator = "ConfigDirsOnly"
config.font_dirs = { "fonts" }
config.font = wezterm.font_with_fallback({ "Maple Mono Normal NF CN", "JetBrains Mono" })
config.font_size = 13

-- 視窗:透明 + 暗色。win32_system_backdrop 在 Windows 11 給毛玻璃模糊,Windows 10 會被忽略。
config.window_background_opacity = 0.8
config.win32_system_backdrop = "Acrylic"
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.hide_tab_bar_if_only_one_tab = false -- INTEGRATED_BUTTONS 需要 tab bar 承載視窗按鈕
config.use_fancy_tab_bar = true

-- 配色:Wombat(與 windows/alacritty.toml 相同)
config.colors = {
  foreground = "#e5e1d8",
  background = "#1f1f1f",
  ansi = { "#000000", "#f7786d", "#bde97c", "#efdfac", "#6ebaf8", "#ef88ff", "#90fdf8", "#e5e1d8" },
  brights = { "#b4b4b4", "#f99f92", "#e3f7a1", "#f2e9bf", "#b3d2ff", "#e5bdff", "#c2fefa", "#ffffff" },
}

-- 鍵綁定:Alt+←/→ 以字為單位移動(送 ESC B / ESC F,同 Alacritty 設定);其餘沿用 WezTerm 預設
config.keys = {
  { key = "LeftArrow", mods = "ALT", action = act.SendString("\x1bB") },
  { key = "RightArrow", mods = "ALT", action = act.SendString("\x1bF") },
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
}

return config
