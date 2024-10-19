return {
  {
    vim.fn.expand("$HOME") .. "/Private/nvim_databricks/lua/nvim-databricks",
    name = "nvim-databricks",
    config = function()
      databricks = require("nvim-databricks")
      databricks.setup({
        settings = {
          profile = "DEFAULT",
          cluster_id = "0503-152818-j2hhktid",
        },
      })

      vim.keymap.set("v", "<leader>sp", function()
        databricks:launch()
      end, { noremap = true })

      vim.keymap.set("n", "<leader>cl", function()
        databricks:clear_context()
      end, { noremap = true })
    end,
  },
}
