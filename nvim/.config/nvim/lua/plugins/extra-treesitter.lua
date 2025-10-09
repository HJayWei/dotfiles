local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.blade = {
  install_info = {
    url = "https://github.com/EmranMR/tree-sitter-blade",
    files = { "src/parser.c" },
    branch = "main",
  },
  filetype = "blade",
}

vim.filetype.add({
  pattern = {
    [".*%.blade%.php"] = "blade",
  },
})

return {
  {
    "jwalton512/vim-blade",
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "c",
        "lua",
        "vim",
        "vimdoc",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "html",
        "css",
        "bash",
        "query",
        "markdown",
        "markdown_inline",
        "blade",
        "go",
        "php",
        "scss",
        "vue",
        "tmux",
        "sql",
      },
      auto_install = true,
      sync_install = false,
    },
  },
}
