return {
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "vue",
        "css",
        "scss",
        "javascript",
        html = {
          mode = "foreground",
        },
      })
    end,
  },
}
