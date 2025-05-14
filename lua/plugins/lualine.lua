return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    branch = "master",
    commit = "2248ef254d0a1488a72041cfb45ca9caada6d994",
    config = function()
      require("lualine").setup({
        options = { theme = "rose-pine" },
        sections = {
          lualine_c = {
            { "filename", path = 1 },
          },
          lualine_x = {
            {
              "searchcount",
              maxcount = 9999,
              timeout = 500,
            },
          },
        },
      })
    end,
  },
}
