local BufferUtils = require("databricks.buffer")
local Config = require("databricks.config")
local Api = require("databricks.api")
local augroup = vim.api.nvim_create_augroup("ScratchBuffer", { clear = true })

local Databricks = {}
Databricks.__index = Databricks

function Databricks:new()
  local config = Config.get_default_config()

  local databricks = setmetatable({
    config = config,
    context_id = nil,
    creds = {},
    api = Api,
    buf = nil,
  }, self)

  return databricks
end

-- function Databricks.write_cmd_to_buffer(_, buf, creds, context_id)
--   local lines = get_visual_selection()
--   assert(lines)
--   local command = table.concat(lines, "\n")
--
--   BufferUtils.write_visual_selection_to_buffer(buf, lines)
--
--   local ok, res = pcall(Api.execute_code, creds, context_id, command)
--
--   if not ok then
--     error(res)
--   else
--     assert(type(res) == "table")
--
--     if res.data ~= nil then
--       print("Output: " .. res.data)
--     end
--
--     BufferUtils.write_output_to_buffer(buf, res, table.getn(lines))
--     return res
--   end
-- end

local databricks_instance = Databricks:new()

function Databricks.setup(self, partial_config)
  --handle function call with dot syntax as opposed to method with colon syntax
  -- databricks.setup(databricks_instance, partial_config) vs databricks_instance:setup(partial_config)
  if self ~= databricks_instance then
    partial_config = self
    self = databricks_instance
  end

  self.config = Config.merge_config(partial_config, self.config)

  print(vim.inspect(self.config))

  if not assert(self.config.settings.profile) then
    error("Databricks profile not set. Please set a profile in the config.")
  end
  if not assert(self.config.settings.cluster_id) then
    error("Databricks Cluster ID is not set. Please set it in the config.")
  end

  self.creds = Config.parse_databricks_config(
    self.config.settings.profile,
    self.config.settings.path
  )
  -- self:create_context_if_not_exists()

  -- if not assert(self.context_id) then
  --   error("Failed to create execution context.")
  -- end

  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    desc = "Set a background buffer on load",
    once = true,
    callback = BufferUtils.create_buffer,
  })
  self.buf = vim.g.databricks_buf

  return self
end

-- function Databricks.create_buffer_on_load()
--   local augroup = vim.api.nvim_create_augroup("ScratchBuffer", { clear = true })
--
--   vim.api.nvim_create_autocmd("VimEnter", {
--     group = augroup,
--     desc = "Set a background buffer on load",
--     once = true,
--     callback = BufferUtils.create_buffer,
--   })
-- end

-- return { setup = setup }
return databricks_instance
