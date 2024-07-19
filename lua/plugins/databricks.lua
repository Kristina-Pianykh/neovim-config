local curr_script_path = vim.fn.expand(vim.fn.expand("%:p"))
local curr_script_dir = vim.fn.expand(vim.fn.expand("%:p:h"))
local wrapper_path = vim.fn.expand(vim.fn.expand("<sfile>:p:h"))
  .. "/lua/plugins/execute_code.py"
local curl = require("plenary.curl")

local CONTEXT_STATUS = {
  running = "Running",
  pending = "Pending",
  error = "Error",
}

local COMMAND_STATUS = {
  running = "Running",
  cancelled = "Cancelled",
  cancelling = "Cancelling",
  finished = "Finished",
  queued = "Queued",
  error = "Error",
}

vim.keymap.set(
  "v",
  "<leader>sp",
  function() --TODO: wrap plugin into module and pass M.main()
    main()
  end,
  { noremap = true }
)

vim.keymap.set("n", "<leader>cc", function()
  clear_context()
end, { noremap = true })

vim.g.databricks_profile = "adb-537208599094554"
vim.g.databricks_cluster_id = "0503-152818-j2hhktid"
-- vim.g.databricks_host = "https://adb-537208599094554.14.azuredatabricks.net"

local function create_buffer()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buf, "*databricks*")
  vim.api.nvim_set_option_value("filetype", "txt", { buf = buf })
  -- print(vim.g.databricks_buf)
  vim.g.databricks_buf = buf
  return buf
end

local function clear_buffer(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

local function contains(arr, val)
  for _, v in ipairs(arr) do
    if v == val then
      return true
    end
  end
  return false
end

local function write_output_to_buffer(buf, output_table, start_line)
  local stringified = vim.fn.json_encode(output_table)
  local lines = vim.fn.split(stringified, "\n")
  table.insert(lines, 1, "Output:")
  table.insert(lines, 1, "")
  local end_line = start_line + table.getn(lines)
  vim.api.nvim_buf_set_lines(buf, start_line, end_line, false, lines)
end

local function write_visual_selection_to_buffer(buf, lines)
  clear_buffer(buf) -- for now: overwrite the buffer with every execution
  vim.api.nvim_buf_set_lines(buf, 0, table.getn(lines), false, lines) -- misalighnment might cause problems here
end

local function get_command_status(context_id, command_id)
  local url = "https://" .. creds.host .. "/api/1.2/commands/status"
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
  }
  local query = {
    clusterId = vim.g.databricks_cluster_id,
    contextId = context_id,
    commandId = command_id,
  }

  local args = {
    headers = header,
    query = query,
  }
  print(vim.inspect({ url, args }))

  local response = curl.get(url, args)
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))
  if response.status == 200 then
    return response_body
  else
    error("Failed to get status of the command with id: " .. command_id)
  end
end

local function wait_command_status_until_finished_or_error(
  context_id,
  command_id
)
  local now = os.time()
  local timeout = 60 * 20 -- 20 seconds TODO: make configurable
  local deadline = now + timeout
  local target_states = { COMMAND_STATUS.finished, COMMAND_STATUS.error }
  local failed_states = { COMMAND_STATUS.cancelled, COMMAND_STATUS.cancelling }

  local attempt = 1
  -- local sleep = attempt * 1000 -- in millies
  local sleep = attempt

  while os.time() < deadline do
    local ok, res = pcall(get_command_status, context_id, command_id)

    if not ok then
      error(res)
    end

    local response_body = res
    local status = response_body.status

    if contains(target_states, status) then
      print("Execution reached target state: " .. status)
      return response_body
    elseif contains(failed_states, status) then
      error("failed to reach Finished or Error, got " .. status)
    else
      os.execute("sleep " .. tonumber(sleep)) -- TODO: replace when wrapping into async
    end

    attempt = attempt + 1
    -- if sleep < 10 * 1000 then
    if sleep < 10 then -- sleep no longer than 10s
      sleep = attempt
    end
  end
  error("Timed out after " .. timeout .. "s.")
end

local function execute_code(creds, context_id, command)
  local url = "https://" .. creds.host .. "/api/1.2/commands/execute"
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
    content_type = "application/json",
  }
  local data = {
    clusterId = vim.g.databricks_cluster_id,
    language = "python",
    contextId = context_id,
    command = command,
  }

  local args = {
    headers = header,
    body = vim.fn.json_encode(data),
  }
  print(vim.inspect({ url, args }))

  local response = curl.post(url, args)
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))

  if response.status ~= 200 then
    error(
      "request failed with status "
        .. response.status
        .. ". Error: "
        .. response_body.error
    )
  end
  local command_id = response_body.id
  local ok, res =
    pcall(wait_command_status_until_finished_or_error, context_id, command_id)

  if not ok then
    error(res)
  else
    return res.results
  end
end

-- function copied from https://www.reddit.com/r/neovim/comments/1b1sv3a/function_to_get_visually_selected_text/
function get_visual_selection()
  local _, srow, scol = unpack(vim.fn.getpos("v"))
  local _, erow, ecol = unpack(vim.fn.getpos("."))

  -- visual line mode
  if vim.fn.mode() == "V" then
    if srow > erow then
      return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
    else
      return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
    end
  end

  -- regular visual mode
  if vim.fn.mode() == "v" then
    if srow < erow or (srow == erow and scol <= ecol) then
      return vim.api.nvim_buf_get_text(
        0,
        srow - 1,
        scol - 1,
        erow - 1,
        ecol,
        {}
      )
    else
      return vim.api.nvim_buf_get_text(
        0,
        erow - 1,
        ecol - 1,
        srow - 1,
        scol,
        {}
      )
    end
  end

  -- visual block mode
  if vim.fn.mode() == "\22" then
    local lines = {}
    if srow > erow then
      srow, erow = erow, srow
    end
    if scol > ecol then
      scol, ecol = ecol, scol
    end
    for i = srow, erow do
      table.insert(
        lines,
        vim.api.nvim_buf_get_text(
          0,
          i - 1,
          math.min(scol - 1, ecol),
          i - 1,
          math.max(scol - 1, ecol),
          {}
        )[1]
      )
    end
    return lines
  end
end

-- local function get_token(profile)
--   command = "databricks auth token -p " .. profile
--   output = vim.fn.system(command)
--   token = vim.json.decode(output).access_token
--   return token
-- end

local function parse_config(profile, config_path)
  if config_path == nil then
    config_path = vim.fn.getenv("HOME") .. "/.databrickscfg"
  end
  -- print(profile)

  --TODO: validate that config_path exists if not handle
  creds = { host = nil, token = nil, profile = nil }

  for line in io.lines(config_path) do
    if creds.host ~= nil then
      if string.starts(line, "token") then
        local tmp = vim.split(line, " = ")
        creds.token = tmp[table.getn(tmp)]
        -- print(creds.token)
        break
      end
    end
    if creds.profile ~= nil then
      if string.starts(line, "host") then
        local tmp = vim.split(line, "https://")
        creds.host = tmp[table.getn(tmp)]
      end
    end
    if line == "[" .. profile .. "]" then
      creds.profile = profile
    end
  end

  -- print(creds.token)
  return creds
end

function string.starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

function is_empty(arg)
  return arg == nil or arg == ""
end

function clear_context()
  local path = curr_script_dir .. "/.execution_context"
  local context_id = nil

  local f = io.open(path, "r")
  if f == nil then
    return
  else
    context_id = f:read("*all")
    f:close()
  end

  assert(context_id)

  local url = "https://" .. creds.host .. "/api/1.2/contexts/destroy"
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
    content_type = "application/json",
  }
  local data =
    { clusterId = vim.g.databricks_cluster_id, contextId = context_id }

  local args = {
    headers = header,
    body = vim.fn.json_encode(data),
  }
  print(vim.inspect({ url, args }))

  local response = curl.post(url, args)
  print(vim.inspect(response))
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))

  os.remove(path)
end

local function create_execution_context(creds)
  local context_id = nil

  local url = "https://" .. creds.host .. "/api/1.2/contexts/create"
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
    content_type = "application/json",
  }
  local data = { clusterId = vim.g.databricks_cluster_id, language = "python" }

  local args = {
    headers = header,
    body = vim.fn.json_encode(data),
  }
  print(vim.inspect({ url, args }))

  local response = curl.post(url, args)
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))

  if response.status ~= 200 then
    error(
      "request failed with status "
        .. response.status
        .. ". Error: "
        .. response_body.error
    )
  end

  context_id = response_body.id
  local f = assert(io.open(curr_script_dir .. "/.execution_context", "w"))
  f:write(context_id)
  f:close()

  print(context_id)
  return context_id
end

local function get_context_status(creds, context_id)
  local url = "https://"
    .. creds.host
    .. "/api/1.2/contexts/status"
    .. "?clusterId="
    .. vim.g.databricks_cluster_id
    .. "&contextId="
    .. context_id
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
    content_type = "application/json",
  }

  local args = {
    headers = header,
  }

  print(vim.inspect({ url, args }))
  local response = curl.get(url, args)
  print(vim.inspect(response))
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))

  if response.status ~= 200 then
    error(
      "Failed to get the status of the execution context. Error: "
        .. response_body.error
    )
  end

  return response_body.status
end

function main()
  local context_id = nil
  local context_status = nil
  local buf = vim.g.databricks_buf

  if buf == nil then
    buf = create_buffer()
  end

  local creds = parse_config(vim.g.databricks_profile, nil)

  local f = io.open(curr_script_dir .. "/.execution_context", "r")
  if f == nil then
    local ok, res = pcall(create_execution_context, creds)

    if ok then
      context_id = res
      context_status = CONTEXT_STATUS.running
    else
      error(res)
    end

    assert(context_id)
  else
    context_id = f:read("*all")
    f:close()
    local ok, res = pcall(get_context_status, creds, context_id)

    if ok then
      context_status = res
    else
      error(res)
    end

    assert(context_status)

    if context_status ~= CONTEXT_STATUS.running then
      if context_status == CONTEXT_STATUS.pending then
        error("Execution context's status is pending. Try later...")
      else
        clear_context()
        local ok, res = create_execution_context(creds)

        if ok then
          context_id = res
          context_status = CONTEXT_STATUS.running
        else
          error(res)
        end
      end
    end
  end
  print(context_id)
  print(context_status)

  local lines = get_visual_selection()
  local command = table.concat(lines)

  write_visual_selection_to_buffer(buf, lines)

  local ok, res = pcall(execute_code, creds, context_id, command)

  if not ok then
    error(res)
  else
    assert(type(res) == "table")

    if res.data ~= nil then
      print("Output: " .. res.data)
    end

    write_output_to_buffer(buf, res, table.getn(lines))
    return res
  end
end

local function setup()
  local augroup = vim.api.nvim_create_augroup("ScratchBuffer", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    desc = "Set a background buffer on load",
    once = true,
    callback = create_buffer,
  })
end

return { setup = setup }
