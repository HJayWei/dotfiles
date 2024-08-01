return {
  {
    "OscarCreator/rsync.nvim",
    build = "make",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("rsync").setup({
        {
          -- triggers `RsyncUp` when fugitive thinks something might have changed in the repo.
          fugitive_sync = false,
          -- triggers `RsyncUp` when you save a file.
          sync_on_save = true,
          -- the path to the project configuration
          project_config_path = ".nvim/rsync.toml",
          -- called when the rsync command exits, provides the exit code and the used command
          on_exit = function(code, command) end,
          -- called when the rsync command prints to stderr, provides the data and the used command
          on_stderr = function(data, command) end,
        },
      })
    end,
  },
}
