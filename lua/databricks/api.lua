local curl = require("plenary.curl")
local string_utils = require("databricks.strings")
local curr_script_dir = vim.fn.expand(vim.fn.expand("%:p:h"))

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

    if string_utils.contains(target_states, status) then
      print("Execution reached target state: " .. status)
      return response_body
    elseif string_utils.contains(failed_states, status) then
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

local function clear_context()
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
