local CURR_SCRIPT_DIR = vim.fn.expand(vim.fn.expand("%:p:h"))
local BufferUtils = require("databricks.buffer")
local Config = require("databricks.config")
local Api = require("databricks.api")

local Databricks = {}
Databricks.__index = Databricks

function Databricks:new()
  local config = Config.get_default_config()

  local databricks = setmetatable({
    config = config,
    context_id = nil,
    creds = {},
    buf = nil,
  }, self)

  return databricks
end

function Databricks.create_context_if_not_exists(self)
  local context_id = nil
  local context_status = nil

  local f = io.open(CURR_SCRIPT_DIR .. "/.execution_context", "r")
  if f == nil then
    local ok, res = pcall(Api.create_execution_context, creds)

    if ok then
      context_id = res
      context_status = Api.CONTEXT_STATUS.running
    else
      error(res)
    end

    assert(context_id)
  else
    context_id = f:read("*all")
    f:close()
    local ok, res = pcall(Api.get_context_status, creds, context_id)

    if ok then
      context_status = res
    else
      error(res)
    end

    assert(context_status)

    if context_status ~= Api.CONTEXT_STATUS.running then
      if context_status == Api.CONTEXT_STATUS.pending then
        error("Execution context's status is pending. Try later...")
      else
        clear_context()
        local ok, res = pcall(Api.create_execution_context, creds)

        if ok then
          context_id = res
          context_status = Api.CONTEXT_STATUS.running
        else
          error(res)
        end
      end
    end
  end
  print(context_id)
  print(context_status)
  self.context_id = context_id
  -- return context_id
end

function Databricks.write_cmd_to_buffer(_, buf, creds, context_id)
  local lines = get_visual_selection()
  assert(lines)
  local command = table.concat(lines, "\n")

  BufferUtils.write_visual_selection_to_buffer(buf, lines)

  local ok, res = pcall(Api.execute_code, creds, context_id, command)

  if not ok then
    error(res)
  else
    assert(type(res) == "table")

    if res.data ~= nil then
      print("Output: " .. res.data)
    end

    BufferUtils.write_output_to_buffer(buf, res, table.getn(lines))
    return res
  end
end

local databricks_instance = Databricks:new()

function Databricks.setup(self, partial_config)
  -- if self ~= databricks_instance then
  --     partial_config = self
  --     self = databricks_instance
  -- end
  self.buf = vim.g.databricks_buf
  if self.buf == nil then
    self.buf = BufferUtils.create_buffer()
  end

  self.config = Config.merge_config(partial_config, self.config) -- TODO: review
  self.creds = Config.get_creds(self.config)
  self.context_id = self:create_context_if_not_exists()
  -- self:write_cmd_to_buffer(self.buf, self.creds, self.context_id)
  self:create_buffer_on_load()
  return self
end

function Databricks.create_buffer_on_load(_)
  local augroup = vim.api.nvim_create_augroup("ScratchBuffer", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    desc = "Set a background buffer on load",
    once = true,
    callback = BufferUtils.create_buffer,
  })
end

-- return { setup = setup }
return databricks_instance
