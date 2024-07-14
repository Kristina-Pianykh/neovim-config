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

vim.keymap.set("v", "<leader>sp", function()
  -- write_to_buffer()
  main()
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

function write_output_to_buffer(buf, output, start_line)
  lines = vim.fn.split(output, "\n")
  table.insert(lines, 1, "")
  -- lines = { output }
  -- print(lines)
  end_line = start_line + table.getn(lines)
  vim.api.nvim_buf_set_lines(buf, start_line, end_line, false, lines)
end

function write_visual_selection_to_buffer(buf, lines)
  -- lines = get_visual_selection()
  clear_buffer(buf) -- for now: overwrite the buffer with every execution
  -- print(table.getn(lines))
  vim.api.nvim_buf_set_lines(buf, 0, table.getn(lines), false, lines) -- misalighnment might cause problems here
end

function execute_code(buf)
  lines_arr = get_visual_selection()
  lines_str = table.concat(lines_arr)
  command = "poetry run python3 "
    .. vim.fn.shellescape(wrapper_path)
    .. " --code "
    .. vim.fn.shellescape(lines_str)
    .. " --profile "
    .. vim.g.databricks_profile
    .. " --cluster_id "
    .. vim.g.databricks_cluster_id
  -- print(command)
  output = vim.fn.system(command)
  -- print(output)
  return output
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

local function clear_context()
  local path = curr_script_dir .. "/.execution_context"
  local f = io.open(path, "r")
  if f == nil then
    return
  else
    f:close()
    assert(os.remove(path))
  end
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
  local specs = { url, args }
  print(vim.inspect(specs))

  local response = curl.post(url, args)
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))

  if response_body.error ~= nil or response.status ~= 200 then
    print("Failed to create execution context")
    if response_body.error ~= nil then
      print(response_body.error)
    end
    return nil
  end

  context_id = response_body.id
  local f = assert(io.open(curr_script_dir .. "/.execution_context", "w"))
  f:write(context_id)
  f:close()

  return context_id
end

local function get_context_status(creds)
  local context_id = nil
  local f = io.open(curr_script_dir .. "/.execution_context", "r")

  if f == nil then
    assert(create_execution_context(creds, 0) ~= nil)
    return CONTEXT_STATUS.running
  else
    context_id = f:read("*all")
    f:close()
  end

  assert(not is_empty(context_id), "context_id is not set") -- TODO: crash the module?
  -- print(vim.inspect(creds))

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
  local specs = { url, args }
  print(vim.inspect(specs))

  local response = curl.get(url, args)
  local response_body = vim.fn.json_decode(response.body)

  print(vim.inspect(response_body))
  if response_body.error ~= nil or response.status ~= 200 then
    print("Failed to get the status of the execution context")
    if response_body.error ~= nil then
      print(response_body.error)
    end
    return nil
  end
  local status = response_body.status
  return status
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
    context_id = create_execution_context(creds)
    context_status = CONTEXT_STATUS.running

    if is_empty(context_id) then
      clear_context()
      context_id = create_execution_context(creds)
    end

    assert(context_id ~= nil)
  else
    context_id = f:read("*all")
    context_status = get_context_status(creds)
    f:close()

    if is_empty(context_status) then
      return
    end

    if context_status ~= CONTEXT_STATUS.running then
      if context_status == CONTEXT_STATUS.pending then
        print("Execution context's status is pending. Try later...")
        return -- TODO: how to handle this correct? stderr? exit(1)?
      else
        clear_context()
        context_id = create_execution_context(creds)
        assert(context_id ~= nil)
        context_status = CONTEXT_STATUS.running
      end
    end
  end
  print(context_id)
  print(context_status)

  -- lines = get_visual_selection()
  -- lines_size = table.getn(lines)
  -- write_visual_selection_to_buffer(buf, lines)
  -- output = execute_code(buf)
  -- write_output_to_buffer(buf, output, lines_size)
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
