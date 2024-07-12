local curr_script_path = vim.fn.expand(vim.fn.expand("%:p"))
local wrapper_path = vim.fn.expand(vim.fn.expand("<sfile>:p:h"))
  .. "/lua/plugins/execute_code.py"

vim.keymap.set("v", "<leader>sp", function()
  -- write_to_buffer()
  main()
end, { noremap = true })

vim.g.databricks_profile = "adb-537208599094554"
vim.g.databricks_cluster_id = "0503-152818-j2hhktid"
vim.g.databricks_host = "https://adb-537208599094554.14.azuredatabricks.net"

local function create_buffer()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buf, "*databricks*")
  vim.api.nvim_set_option_value("filetype", "txt", { buf = buf })
  print(vim.g.databricks_buf)
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
  print(lines)
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
  print(command)
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

local function get_token(profile)
  command = "databricks auth token -p "
    .. profile
    .. " | jq "
    .. vim.fn.shellescape('.["access_token"]')
  token = vim.fn.system(command)
  -- print(token)
  return token
end

local function parse_config(profile, config_path)
  if config_path == nil then
    config_path = vim.fn.getenv("HOME") .. "/.databrickscfg"
  end
  print(profile)

  --TODO: validate that config_path exists if not handle
  creds = { host = nil, token = nil, profile = nil }

  for line in io.lines(config_path) do
    -- print("[" .. profile .. "]")
    if creds.profile ~= nil then
      if string.starts(line, "host") then
        local pattern = "https://%S+"
        creds.host = string.match(line, pattern)
        print(creds.host)
        break
        -- host_start = vim.fn.match(line, "https")
        -- print(host_start)
        -- host_end = vim.fn.match(line, "$")
        -- print(host_end)
      end
    end
    if line == "[" .. profile .. "]" then
      creds.profile = profile
    end
  end

  creds.token = get_token(profile)
  print(creds.token)
  return creds
end

function string.starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

function main()
  local buf = vim.g.databricks_buf
  if buf == nil then
    buf = create_buffer()
  end

  -- local token = get_token(vim.g.databricks_profile)
  local creds = parse_config(vim.g.databricks_profile, nil)
  for k, v in pairs(creds) do
    print(k, v)
  end

  lines = get_visual_selection()
  lines_size = table.getn(lines)
  write_visual_selection_to_buffer(buf, lines)
  output = execute_code(buf)
  write_output_to_buffer(buf, output, lines_size)
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
