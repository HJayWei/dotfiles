-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- Quit Window
map({ "v", "n", "s", "o" }, "<C-q>", "<cmd>q<cr><esc>", { desc = "Quit file" })

-- Delete Buffer
map("n", "<S-q>", LazyVim.ui.bufremove, { desc = "Delete Buffer" })
