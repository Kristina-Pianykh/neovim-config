return {
  --- Uncomment the two plugins below if you want to manage the language servers from neovim
  -- {'williamboman/mason.nvim'},
  -- {'williamboman/mason-lspconfig.nvim'},
  -- here you can setup the language servers
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    config = function()
      local lsp_zero = require('lsp-zero')

      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({buffer = bufnr})
      end)
    end
  },
  {
    'neovim/nvim-lspconfig',
    -- config = function()
    --   require'lspconfig'.pyright.setup{}
    -- end
  },

  -- Autocompletion
  {
    'hrsh7th/cmp-nvim-lsp',
    config = function()
      local lspconfig = require('lspconfig')
      local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
      lspconfig.pyright.setup({capabilities = lsp_capabilities})
    end
  },
  {'hrsh7th/nvim-cmp'},

  -- Snippets
  {'L3MON4D3/LuaSnip'}
}
