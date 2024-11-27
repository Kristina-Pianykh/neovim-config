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
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })
vim.opt.clipboard:append({ "unnamedplus" })
vim.keymap.set("v", "P", '"_dp', { desc = "[P]ut without yanking" })
vim.keymap.set("n", "<leader>sc", "q:")

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

-- motions when a line wraps
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "$", "g$")
vim.keymap.set("n", "^", "g^")
vim.keymap.set("n", "0", "g0")

-- split window navigation
vim.keymap.set("n", "<Space>h", "<C-w>h", { noremap = true })
vim.keymap.set("n", "<Space>j", "<C-w>j", { noremap = true })
vim.keymap.set("n", "<Space>k", "<C-w>k", { noremap = true })
vim.keymap.set("n", "<Space>l", "<C-w>l", { noremap = true })

-- Diagnostic keymaps
-- vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copnightfox-nvim;ing) text",
  group = vim.api.nvim_create_augroup(
    "kickstart-highlight-yank",
    { clear = true }
  ),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Define LSP specific keymaps",
  group = vim.api.nvim_create_augroup("lsp", { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "<leader>rn", function()
      vim.lsp.buf.rename()
    end, opts)
    vim.keymap.set("n", "[d", function()
      vim.diagnostic.goto_next()
    end, opts)
    vim.keymap.set("n", "]d", function()
      vim.diagnostic.goto_prev()
    end, opts)
    vim.keymap.set("n", "gs", function()
      vim.lsp.buf.signature_help()
    end, opts)
    vim.keymap.set("n", "<leader>a", function()
      vim.lsp.buf.code_action()
    end, opts)
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("strip_whitespaces", { clear = true }),
  command = ":%s/s+$//e",
})
