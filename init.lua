vim.filetype.add({
  pattern = {
    [".*/zfunctions/.*"] = "zsh",
  },
})

require("keymaps")
require("lazy-bootstrap")

local plugins = {
  "psliwka/vim-smoothie",
  "tomtom/tcomment_vim",
  "rafcamlet/nvim-luapad",
  "nvim-lua/plenary.nvim",
  "LunarVim/bigfile.nvim",
  -- "towolf/vim-helm",
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
  -- require("plugins/lsp"),
  require("plugins/lsp-new"),
  require("plugins/harpoon"),
  require("plugins/formatter"),
  require("plugins/render-markdown"),
  require("plugins/yazi"),
  -- require("plugins/dbricks"),
  -- require("plugins/databricks"),
}

local opts = {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
}

-- REMOVE AFTER MIGRATING TO NEOVIM LSP
vim.deprecate = function() end
require("lazy").setup(plugins, opts)
