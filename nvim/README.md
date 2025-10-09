### bufferline issue

```lua
-- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/colorscheme.lua
specs = {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        integrations = {
          bufferline = true,
        },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    optional = true,
  },
},
```
