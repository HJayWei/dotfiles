return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          root_markers = { "composer.json", ".git" },
        },
      },
    },
  },
}
