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
        }
      })

      vim.keymap.set("n", "hq", function() harpoon:list():append() end)
      vim.keymap.set("n", "he", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

      vim.keymap.set("n", "h1", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "h2", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "h3", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "h4", function() harpoon:list():select(4) end)
      vim.keymap.set("n", "h5", function() harpoon:list():select(5) end)
      vim.keymap.set("n", "h6", function() harpoon:list():select(6) end)

      -- Toggle previous & next buffers stored within Harpoon list
      local navigation_opts = { ui_nav_wrap = true }
      vim.keymap.set("n", "hf", function() harpoon:list():prev(navigation_opts) end)
      vim.keymap.set("n", "hp", function() harpoon:list():next(navigation_opts) end)

      end
  }
}
