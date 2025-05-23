return {
  {
    "mhartington/formatter.nvim",
    config = function()
      -- Utilities for creating configurations
      local util = require("formatter.util")

      -- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
      require("formatter").setup({
        -- Enable or disable logging
        logging = true,
        -- Set the log level
        log_level = vim.log.levels.WARN,
        -- All formatter configurations are opt-in
        filetype = {
          lua = {
            require("formatter.filetypes.lua").stylua,
          },
          json = {
            require("formatter.defaults.prettierd"),
          },
          python = {
            require("formatter.filetypes.python").ruff,
          },
          terraform = {
            require("formatter.filetypes.terraform").terraformfmt,
          },
          nix = {
            require("formatter.filetypes.nix").nixfmt,
          },
          java = {
            function()
              return {
                exe = "google-java-format",
                args = {
                  util.escape_path(util.get_current_buffer_file_path()),
                  "--replace",
                },
                stdin = true,
              }
            end,
          },
          c = {
            function()
              return {
                exe = "astyle",
                args = { "--indent=spaces=4", "--mode=c" },
                stdin = true,
              }
            end,
            -- require("formatter.filetypes.c").astyle,
          },
          -- Use the special "*" filetype for defining formatter configurations on
          -- any filetype
          ["*"] = {
            -- "formatter.filetypes.any" defines default configurations for any
            -- filetype
            require("formatter.filetypes.any").remove_trailing_whitespace,
          },
        },
      })

      local augroup = vim.api.nvim_create_augroup
      local autocmd = vim.api.nvim_create_autocmd
      augroup("__formatter__", { clear = true })
      autocmd("BufWritePost", {
        group = "__formatter__",
        command = ":FormatWrite",
      })
    end,
  },
}
