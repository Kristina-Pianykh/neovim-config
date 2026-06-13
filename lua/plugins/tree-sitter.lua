return {
  { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "main",
    main = "nvim-treesitter",
    init = function()
      vim.filetype.add({
        extension = { gotmpl = "gotmpl" },
        pattern = {
          [".*/templates/.*%.tpl"] = "helm",
          [".*/templates/.*%.ya?ml"] = "helm",
          ["helmfile.*%.ya?ml"] = "helm",
        },
      })
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          -- Enable treesitter highlighting and disable regex syntax
          pcall(vim.treesitter.start)
          -- Enable treesitter-based indentation
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      local ensureInstalled = {
        "lua",
        "vim",
        "python",
        "hcl",
        "terraform",
        "java",
        "yaml",
        "nix",
        "go",
        "gomod",
        "gosum",
        "json",
        "css",
        "kotlin",
        "helm",
        "gotmpl",
        "javascript",
        "typescript",
        "svelte",
        "sql",
      }
      local alreadyInstalled = require("nvim-treesitter.config").get_installed()
      local parsersToInstall = vim
        .iter(ensureInstalled)
        :filter(function(parser)
          return not vim.tbl_contains(alreadyInstalled, parser)
        end)
        :totable()
      require("nvim-treesitter").install(parsersToInstall)
    end,
  },
}
