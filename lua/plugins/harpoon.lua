return {
	{
		"ThePrimeagen/harpoon", -- lets goooo
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")

			harpoon:setup({
				settings = {
					save_on_toggle = true,
				},
			})

			vim.keymap.set("n", "<leader>q", function()
				harpoon:list():append()
			end)
			vim.keymap.set("n", "<leader>e", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end)

			vim.keymap.set("n", "<leader>1", function()
				harpoon:list():select(1)
			end)
			vim.keymap.set("n", "<leader>2", function()
				harpoon:list():select(2)
			end)
			vim.keymap.set("n", "<leader>3", function()
				harpoon:list():select(3)
			end)
			vim.keymap.set("n", "<leader>4", function()
				harpoon:list():select(4)
			end)
			vim.keymap.set("n", "<leader>5", function()
				harpoon:list():select(5)
			end)
			vim.keymap.set("n", "<leader>6", function()
				harpoon:list():select(6)
			end)

			-- Toggle previous & next buffers stored within Harpoon list
			local navigation_opts = { ui_nav_wrap = true }
			vim.keymap.set("n", "<leader>f", function()
				harpoon:list():prev(navigation_opts)
			end)
			vim.keymap.set("n", "<leader>p", function()
				harpoon:list():next(navigation_opts)
			end)
		end,
	},
}
