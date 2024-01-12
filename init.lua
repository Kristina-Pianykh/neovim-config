vim.g.mapleader = ","
vim.opt.termguicolors = true
vim.opt.relativenumber = true
vim.opt.pumheight = 10
vim.opt.mouse = "a"
vim.opt.hlsearch = true
vim.opt.clipboard:append { "unnamedplus" }
-- fix shit WSL clipboard
vim.g.clipboard = {
	 name = "WslClipboard",
	 copy = {
			["+"] = "clip.exe",
			["*"] = "clip.exe",
		},
	 paste = {
			["+"] = "powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
			["*"] = "powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
	 },
	 cache_enabled = 0,
}
vim.opt.signcolumn = "yes:1"
vim.opt.laststatus = 3
vim.keymap.set("n", "mo", "o<Esc>k")
vim.keymap.set("n", "mO", "O<Esc>j")

-- split window navigation
vim.keymap.set("n", "<Space>h", "<C-w>h", { noremap = true })
vim.keymap.set("n", "<Space>j", "<C-w>j", { noremap = true })
vim.keymap.set("n", "<Space>k", "<C-w>k", { noremap = true })
vim.keymap.set("n", "<Space>l", "<C-w>l", { noremap = true })

-- bootstrap nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
 {
		"EdenEast/nightfox.nvim",
		config = function()
			require("nightfox").setup({
				options = {
					styles = {
						types = "NONE",
						numbers = "NONE",
						strings = "NONE",
						comments = "NONE",
						keywords = "bold",
						constants = "NONE",
						functions = "NONE",
						operators = "NONE",
						variables = "NONE",
						conditionals = "NONE",
						virtual_text = "NONE",
					}
				}
			})
			vim.cmd("colorscheme nordfox")
		end,
	},
	"vim-smoothie"
})
