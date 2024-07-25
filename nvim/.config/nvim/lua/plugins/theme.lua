return {
  {
    "sainnhe/sonokai",
    config = function()
      vim.g.sonokai_style = "atlantis"
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "catppuccin-frappe",
      colorscheme = "sonokai",
    },
  },
}
