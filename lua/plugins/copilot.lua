return {
	{
		"github/copilot.vim",
		config = function()
			vim.keymap.set("i", "<C-Enter>", 'copilot#Accept("\\<CR>")', {
				expr = true,
				replace_keycodes = false,
				silent = true,
			})
		end,
	},
}
