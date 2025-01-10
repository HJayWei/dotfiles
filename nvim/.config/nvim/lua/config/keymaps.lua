-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- Quit Window
map({ "v", "n", "s", "o" }, "<C-q>", "<cmd>q<cr><esc>", { desc = "Quit file" })

-- Delete Buffer
local deleteBuffer = function()
  Snacks.bufdelete()
end

map("n", "<S-q>", deleteBuffer, { desc = "Delete Buffer" })

-- Move the cursor to the first (^ or _)/last (g_) non-whitespace character
map({ "v", "n" }, "<M-h>", "^", { desc = "Move to first non-whitespace character" })
map({ "v", "n" }, "<M-l>", "g_", { desc = "Move to last non-whitespace character" })
map("i", "<M-h>", "<esc>I", { desc = "Move to first non-whitespace character" })
map("i", "<M-l>", "<esc>A", { desc = "Move to last non-whitespace character" })
