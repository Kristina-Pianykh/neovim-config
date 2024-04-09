-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

vim.opt.termguicolors = true
vim.opt.relativenumber = true
vim.opt.pumheight = 10
vim.opt.mouse = "a"
vim.opt.hlsearch = true
vim.opt.clipboard:append({ "unnamedplus" })

-- use 2 whitespaces for indentation instead of tabs
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false
vim.opt.signcolumn = "yes:1"
vim.opt.laststatus = 3
vim.keymap.set("n", "mo", "o<Esc>k")
vim.keymap.set("n", "mO", "O<Esc>j")

-- split window navigation
vim.keymap.set("n", "<Space>h", "<C-w>h", { noremap = true })
vim.keymap.set("n", "<Space>j", "<C-w>j", { noremap = true })
vim.keymap.set("n", "<Space>k", "<C-w>k", { noremap = true })
vim.keymap.set("n", "<Space>l", "<C-w>l", { noremap = true })

-- Diagnostic keymaps
-- TODO: remap this section
vim.keymap.set("n", "gp", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" }) --TODO: fix telescope file search
vim.keymap.set("n", "gn", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copnightfox-nvim;ing) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
