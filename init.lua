require("keymaps")
require("lazy-bootstrap")

local plugins = {
  "psliwka/vim-smoothie",
  "tomtom/tcomment_vim",
  "rafcamlet/nvim-luapad",
  "nvim-lua/plenary.nvim",
  "LunarVim/bigfile.nvim",
  require("plugins/tree-sitter"),
  -- syntax highliting and indentation support
  -- "sheerun/vim-polyglot",
  -- require("plugins/nightfox"),
  require("plugins/rosepine"),
  require("plugins/nvim-surround"),
  require("plugins/nvim-autopairs"),
  require("plugins/lualine"),
  require("plugins/copilot"),
  require("plugins/telescope"),
  require("plugins/lsp"),
  require("plugins/harpoon"),
  require("plugins/formatter"),
  require("plugins/markdown-preview"),
}

local opts = {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
}

require("lazy").setup(plugins, opts)

databricks = require("databricks")
databricks.setup({
  settings = {
    profile = "DEFAULT",
    cluster_id = "0503-152818-j2hhktid",
  },
})

vim.keymap.set("v", "<leader>sp", function()
  databricks:launch()
end, { noremap = true })

vim.keymap.set("n", "<leader>cl", function()
  databricks:clear_context()
end, { noremap = true })
