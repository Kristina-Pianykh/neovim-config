local curr_script_dir = vim.fn.expand(vim.fn.expand("%:p:h"))
local buffer_utils = require("databricks.buffer")
local config = require("databricks.buffer")
local api = require("databricks.api")

local databricks = {}

function main()
  local context_id = nil
  local context_status = nil
  local buf = vim.g.databricks_buf

  if buf == nil then
    buf = buffer_utils.create_buffer()
  end

  local creds = config.parse_config(vim.g.databricks_profile, nil)

  local f = io.open(curr_script_dir .. "/.execution_context", "r")
  if f == nil then
    local ok, res = pcall(api.create_execution_context, creds)

    if ok then
      context_id = res
      context_status = api.CONTEXT_STATUS.running
    else
      error(res)
    end

    assert(context_id)
  else
    context_id = f:read("*all")
    f:close()
    local ok, res = pcall(api.get_context_status, creds, context_id)

    if ok then
      context_status = res
    else
      error(res)
    end

    assert(context_status)

    if context_status ~= api.CONTEXT_STATUS.running then
      if context_status == api.CONTEXT_STATUS.pending then
        error("Execution context's status is pending. Try later...")
      else
        clear_context()
        local ok, res = pcall(api.create_execution_context, creds)

        if ok then
          context_id = res
          context_status = api.CONTEXT_STATUS.running
        else
          error(res)
        end
      end
    end
  end
  print(context_id)
  print(context_status)

  local lines = get_visual_selection()
  assert(lines)
  local command = table.concat(lines, "\n")

  buffer_utils.write_visual_selection_to_buffer(buf, lines)

  local ok, res = pcall(api.execute_code, creds, context_id, command)

  if not ok then
    error(res)
  else
    assert(type(res) == "table")

    if res.data ~= nil then
      print("Output: " .. res.data)
    end

    buffer_utils.write_output_to_buffer(buf, res, table.getn(lines))
    return res
  end
end

local function setup()
  local augroup = vim.api.nvim_create_augroup("ScratchBuffer", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    desc = "Set a background buffer on load",
    once = true,
    callback = buffer_utils.create_buffer,
  })
end

return { setup = setup }
