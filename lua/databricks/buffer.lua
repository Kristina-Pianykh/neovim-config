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
