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

    local lua_opts = lsp_zero.nvim_lua_ls()
    require("lspconfig").lua_ls.setup(lua_opts)
    require("lspconfig").pyright.setup({})
    require("lspconfig").terraformls.setup({
      filetypes = { "terraform" }, -- TODO: workaround to disable lsp support for *.tfvars files. Might be fixed in next nvim release https://github.com/hashicorp/terraform-ls/issues/1464
    })
    require("lspconfig").tflint.setup({})
    require("lspconfig").java_language_server.setup({
      cmd = { "java-language-server" },
      handlers = java_handlers,
    })

    lsp_zero.preset("recommended") -- not sure about the order for this line

    lsp_zero.setup_servers({ "pyright" })

    require("lspconfig").gopls.setup({})
    local autocmd = vim.api.nvim_create_autocmd
    autocmd("BufWritePre", {
      pattern = "*.go",
      callback = function()
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { "source.organizeImports" } }
        -- buf_request_sync defaults to a 1000ms timeout. Depending on your
        -- machine and codebase, you may want longer. Add an additional
        -- argument after params if you find that you have to write the file
        -- twice for changes to be saved.
        -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
        local result =
          vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
        for cid, res in pairs(result or {}) do
          for _, r in pairs(res.result or {}) do
            if r.edit then
              local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding
                or "utf-16"
              vim.lsp.util.apply_workspace_edit(r.edit, enc)
            end
          end
        end
        vim.lsp.buf.format({ async = false })
      end,
    })

    -- require("lspconfig").clangd.setup({})
    require("lspconfig").ccls.setup({
      init_options = {
        cache = {
          directory = ".ccls-cache",
        },
      },
    })
  end,
}
