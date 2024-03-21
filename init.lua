-- append current directory to package.path global variable
-- so that lua can find the plugins
cwd = vim.fn.stdpath("config") .. vim.fn.getcwd()
package.path = package.path .. ";" .. cwd .. "/lua/?.lua"

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
},
{
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
})
