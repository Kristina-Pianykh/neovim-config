local curl = require("plenary.curl")
local StringUtils = require("databricks.strings")
local BufferUtils = require("databricks.buffer")
local CURR_SCRIPT_DIR = vim.fn.expand(vim.fn.expand("%:p:h"))

local M = {}

M.CONTEXT_STATUS = {
  running = "Running",
  pending = "Pending",
  error = "Error",
}

M.COMMAND_STATUS = {
  running = "Running",
  cancelled = "Cancelled",
  cancelling = "Cancelling",
  finished = "Finished",
  queued = "Queued",
  error = "Error",
}

M.get_command_status = function(creds, cluster_id, context_id, command_id)
  local url = "https://" .. creds.host .. "/api/1.2/commands/status"
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
  }
  local query = {
    clusterId = cluster_id,
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

M.wait_command_status_until_finished_or_error = function(
  creds,
  cluster_id,
  context_id,
  command_id
)
  local now = os.time()
  local timeout = 60 * 20 -- 20 seconds TODO: make configurable
  local deadline = now + timeout
  local target_states = { M.COMMAND_STATUS.finished, M.COMMAND_STATUS.error }
  local failed_states =
    { M.COMMAND_STATUS.cancelled, M.COMMAND_STATUS.cancelling }

  local attempt = 1
  -- local sleep = attempt * 1000 -- in millies
  local sleep = attempt

  while os.time() < deadline do
    local ok, res =
      pcall(M.get_command_status, creds, cluster_id, context_id, command_id)

    if not ok then
      error(res)
    end

    local response_body = res
    local status = response_body.status

    if StringUtils.contains(target_states, status) then
      print("Execution reached target state: " .. status)
      return response_body
    elseif StringUtils.contains(failed_states, status) then
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

M.execute_code = function(creds, cluster_id, context_id, command)
  local url = "https://" .. creds.host .. "/api/1.2/commands/execute"
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
    content_type = "application/json",
  }
  local data = {
    clusterId = cluster_id,
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
  local ok, res = pcall(
    M.wait_command_status_until_finished_or_error,
    creds,
    cluster_id,
    context_id,
    command_id
  )

  if not ok then
    error(res)
  else
    return res.results
  end
end

M.clear_context = function(cluster_id)
  local path = CURR_SCRIPT_DIR .. "/.execution_context"
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
  local data = { clusterId = cluster_id, contextId = context_id }

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

M.create_execution_context = function(creds, cluster_id)
  local context_id = nil

  local url = "https://" .. creds.host .. "/api/1.2/contexts/create"
  local header = {
    Authorization = "Bearer " .. creds.token,
    accept = "application/json",
    content_type = "application/json",
  }
  local data = { clusterId = cluster_id, language = "python" }

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
  local f = assert(io.open(CURR_SCRIPT_DIR .. "/.execution_context", "w"))
  f:write(context_id)
  f:close()

  print(context_id)
  return context_id
end

M.get_context_status = function(creds, cluster_id, context_id)
  local url = "https://"
    .. creds.host
    .. "/api/1.2/contexts/status"
    .. "?clusterId="
    .. cluster_id
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

function M.write_cmd_to_buffer(buf, creds, cluster_id, context_id)
  local lines = StringUtils.get_visual_selection()
  assert(lines)
  local command = table.concat(lines, "\n")

  BufferUtils.write_visual_selection_to_buffer(buf, lines)

  local ok, res = pcall(M.execute_code, creds, cluster_id, context_id, command)

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

function M.create_context_if_not_exists(creds, cluster_id)
  local context_id = nil
  local context_status = nil

  local f = io.open(CURR_SCRIPT_DIR .. "/.execution_context", "r")
  if f == nil then
    local ok, res = pcall(M.create_execution_context, creds, cluster_id)

    if ok then
      context_id = res
      context_status = M.CONTEXT_STATUS.running
    else
      error(res)
    end

    assert(context_id)
  else
    context_id = f:read("*all")
    f:close()
    assert(context_id)
    local ok, res = pcall(M.get_context_status, creds, cluster_id, context_id)

    if ok then
      context_status = res
    else
      error(res)
    end

    assert(context_status)

    if context_status ~= M.CONTEXT_STATUS.running then
      if context_status == M.CONTEXT_STATUS.pending then
        error("Execution context's status is pending. Try later...")
      else
        clear_context()
        local ok, res = pcall(M.create_execution_context, creds, cluster_id)

        if ok then
          context_id = res
          context_status = M.CONTEXT_STATUS.running
        else
          error(res)
        end
      end
    end
  end
  print(context_id)
  print(context_status)
  if not assert(context_id) then
    error("Failed to create execution context.")
  end
  return context_id
end

function M.launch(creds, cluster_id)
  local context_id = M.create_context_if_not_exists(creds, cluster_id)
  if not assert(context_id) then
    error("Failed to create execution context.")
  end
  M.write_cmd_to_buffer(vim.g.databricks_buf, creds, cluster_id, context_id)
end

return M
