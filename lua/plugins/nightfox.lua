return {
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
}
