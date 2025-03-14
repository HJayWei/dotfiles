if vim.g.neovide then
  vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  vim.keymap.set("i", "<D-v>", "<C-R>+") -- Paste insert mode
  vim.keymap.set("t", "<D-v>", '<C-\\><C-N>"+pa') -- Paste terminal mode

  vim.g.transparency = 0.9
  vim.g.neovide_transparency = 0.9
  vim.g.neovide_input_macos_option_key_is_meta = "both"
  vim.g.neovide_cursor_vfx_mode = "ripple"

  vim.env.TERM = "xterm-256color"

  local default_path = vim.fn.expand("~/Project")
  vim.api.nvim_set_current_dir(default_path)
end
