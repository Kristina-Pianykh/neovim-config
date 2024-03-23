require 'keymaps'
require 'lazy-bootstrap'

require("lazy").setup({
  "psliwka/vim-smoothie",
  "tomtom/tcomment_vim",
  -- syntax highliting and indentation support
  -- "sheerun/vim-polyglot",
  require 'plugins/nightfox',
  require 'plugins/nvim-surround',
  require 'plugins/nvim-autopairs',
  require 'plugins/lualine',
  require 'plugins/copilot',
  require 'plugins/telescope',
  require 'plugins/tree-sitter',
  require 'plugins/lsp'
},
{
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    }
  }
})
