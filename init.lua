require 'keymaps'
require 'lazy-bootstrap'

local plugins = {
  "psliwka/vim-smoothie",
  "tomtom/tcomment_vim",
  require 'plugins/tree-sitter',
  -- syntax highliting and indentation support
  -- "sheerun/vim-polyglot",
  require 'plugins/nightfox',
  require 'plugins/nvim-surround',
  require 'plugins/nvim-autopairs',
  require 'plugins/lualine',
  require 'plugins/copilot',
  require 'plugins/telescope',
  require 'plugins/lsp',
  require 'plugins/harpoon',
}

local opts = {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
}

require('lazy').setup(plugins, opts)
