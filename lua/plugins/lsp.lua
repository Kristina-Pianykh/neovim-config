local java_handlers = {
  ["client/registerCapability"] = function(err, result, ctx, config)
    local registration = {
      registrations = { result },
    }
    return vim.lsp.handlers["client/registerCapability"](
      err,
      registration,
      ctx,
      config
    )
  end,
}

return {
  --- Uncomment the two plugins below if you want to manage the language servers from neovim
  -- {'williamboman/mason.nvim'},
  -- {'williamboman/mason-lspconfig.nvim'},

  "VonHeikemen/lsp-zero.nvim",
  branch = "v3.x",
  dependencies = {
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/nvim-cmp" },
    { "L3MON4D3/LuaSnip" },
  },

  config = function()
    local lsp_zero = require("lsp-zero")
    lsp_zero.extend_lspconfig()

    lsp_zero.on_attach(function(client, bufnr)
      -- see :help lsp-zero-keybindings
      -- to learn the available actions
      lsp_zero.default_keymaps({ buffer = bufnr })
    end)

    -- local lua_opts = lsp_zero.nvim_lua_ls()
    -- require('lspconfig').lua_ls.setup(lua_opts)
    require("lspconfig").pyright.setup({})
    require("lspconfig").terraformls.setup({
      filetypes = { "terraform" }, -- TODO: workaround to disable lsp support for *.tfvars files. Might be fixed in next nvim release https://github.com/hashicorp/terraform-ls/issues/1464
    })
    require("lspconfig").tflint.setup({})
    require("lspconfig").java_language_server.setup({
      cmd = { "java-language-server" },
      handlers = java_handlers,
    })

    lsp_zero.preset("recommended")

    lsp_zero.setup_servers({ "pyright" })
  end,
}
