return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          layout_strategy = "vertical",
          -- People say it's slow
          -- rather use rg?
          -- https://github.com/nvim-telescope/telescope.nvim/issues/522#issuecomment-777384452
          file_ignore_patterns = {
            "%.o",
            "%.class",
            "%.out",
            "%.a",
            "%.devenv",
            "%.direnv",
          },
          layout_config = {
            height = 0.9,
            -- preview_cutoff = 0,
            preview_height = 0.7,
          },
          path_display = {
            "truncate",
          },
        },
        pickers = {
          find_files = {
            find_command = {
              "rg",
              "--files",
              "--max-count",
              "0", -- 0 means no limit
            },
          },
          buffers = {
            initial_mode = "normal",
          },
          lsp_references = {
            initial_mode = "normal",
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      -- Enable Telescope extensions if they are installed
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<Space>p", builtin.find_files, {})
      vim.keymap.set("n", "<Space>g", builtin.live_grep, {})

      vim.keymap.set(
        "n",
        "<leader>sh",
        builtin.help_tags,
        { desc = "[S]earch [H]elp" }
      )
      vim.keymap.set(
        "n",
        "<leader>sk",
        builtin.keymaps,
        { desc = "[S]earch [K]eymaps" }
      )
      vim.keymap.set(
        "n",
        "<leader>sf",
        builtin.find_files,
        { desc = "[S]earch [F]iles" }
      )
      vim.keymap.set(
        "n",
        "<leader>ss",
        builtin.builtin,
        { desc = "[S]earch [S]elect Telescope" }
      )
      vim.keymap.set(
        "n",
        "<leader>sw",
        builtin.grep_string,
        { desc = "[S]earch current [W]ord" }
      )
      vim.keymap.set(
        "n",
        "gr",
        builtin.lsp_references,
        { desc = "Lists LSP references for word under the cursor" }
      )
      vim.keymap.set(
        "n",
        "gi",
        builtin.lsp_implementations,
        { desc = "Lists LSP implementations for word under the cursor" }
      )
      vim.keymap.set(
        "n",
        "<leader>sd",
        builtin.diagnostics,
        { desc = "[S]earch [D]iagnostics" }
      )
      vim.keymap.set(
        "n",
        "<leader>sr",
        builtin.resume,
        { desc = "[S]earch [R]esume" }
      )
      vim.keymap.set(
        "n",
        "<leader>s.",
        builtin.oldfiles,
        { desc = '[S]earch Recent Files ("." for repeat)' }
      )
      vim.keymap.set(
        "n",
        "<leader><leader>",
        builtin.buffers,
        { desc = "[ ] Find existing buffers" }
      )
      vim.keymap.set(
        "n",
        "<leader>sr",
        builtin.registers,
        { desc = "[S]earch [R]egisters" }
      )
      vim.keymap.set(
        "n",
        "<leader>ch",
        builtin.git_commits,
        { desc = "[S]earch [R]egisters" }
      )

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set("n", "<leader>/", function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(
          require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
          })
        )
      end, { desc = "[/] Fuzzily search in current buffer" })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set("n", "<leader>sn", function()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
      end, { desc = "[S]earch [N]eovim files" })
    end,
  },
}
