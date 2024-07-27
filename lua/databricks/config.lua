local M = {}

M.parse_config = function(profile, config_path)
  if config_path == nil then
    config_path = vim.fn.getenv("HOME") .. "/.databrickscfg"
  end
  -- print(profile)

  --TODO: validate that config_path exists if not handle
  local creds = { host = nil, token = nil, profile = nil }

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

return M
