return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- php packages --
        "intelephense",
        "php-debug-adapter",
        "pint",
        -- rust packages --
        "codelldb",
        "rust-analyzer",
        -- vue packages --
        "vetur-vls",
        -- javascript packages --
        "js-debug-adapter",
        "prettier",
        "vtsls",
        -- others packages --
        "bash-language-server",
        "json-lsp",
        "lua-language-server",
        "markdown-toc",
        "markdownlint-cli2",
        "marksman",
        "shellcheck",
        "shfmt",
        "stylua",
      },
      run_on_start = true,
      auto_update = false,
    },
  },
}
