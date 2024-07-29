return {
  {
    "ThePrimeagen/harpoon", -- lets goooo
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local harpoon = require("harpoon")
      local conf = require("telescope.config").values

      harpoon:setup({
        settings = {
          save_on_toggle = true,
        },
      })

      -- basic telescope configuration
      local function toggle_telescope(harpoon_files)
        local finder = function()
          local paths = {}
          for _, item in ipairs(harpoon_files.items) do
            table.insert(paths, item.value)
          end

          return require("telescope.finders").new_table({
            results = paths,
          })
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = finder(),
            initial_mode = "normal",
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              map("n", "dd", function()
                local state = require("telescope.actions.state")
                local selected_entry = state.get_selected_entry()
                local current_picker = state.get_current_picker(prompt_bufnr)

                table.remove(harpoon_files.items, selected_entry.index)
                current_picker:refresh(finder())
              end)
              return true
            end,
          })
          :find()
      end

      vim.keymap.set("n", "<leader>q", function()
        harpoon:list():add()
      end)
      -- vim.keymap.set("n", "<leader>e", function()
      --   harpoon.ui:toggle_quick_menu(harpoon:list())
      -- end)
      vim.keymap.set("n", "<leader>e", function()
        toggle_telescope(harpoon:list())
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
      -- vim.keymap.set("n", "<leader>p", function()
      --   harpoon:list():next(navigation_opts)
      -- end)
    end,
  },
}
