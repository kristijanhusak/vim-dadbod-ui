local config = require('db_ui.config')

local M = {}

-- Read JSON file and parse it
function M.readfile(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return {}
  end
  
  local content = vim.fn.readfile(filepath)
  local json_str = table.concat(content, '\n')
  
  if json_str == '' then
    return {}
  end
  
  local success, result = pcall(vim.fn.json_decode, json_str)
  if success then
    return result
  else
    return {}
  end
end

-- Write data to JSON file
function M.writefile(filepath, data)
  local dir = vim.fn.fnamemodify(filepath, ':h')
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
  
  local json_str = vim.fn.json_encode(data)
  local lines = vim.split(json_str, '\n')
  return vim.fn.writefile(lines, filepath)
end

-- Create a slug from a string (replace spaces and special chars)
function M.slug(str)
  return str:gsub('[^%w%-_]', '-'):gsub('%-+', '-'):gsub('^%-+', ''):gsub('%-+$', '')
end

-- Input function that handles empty strings
function M.input(prompt, default)
  default = default or ''
  local result = vim.fn.input(prompt, default)
  return result or ''
end

-- Enhanced inputlist that works better with Lua
function M.inputlist(items)
  if type(items) == 'table' then
    for i, item in ipairs(items) do
      print(string.format('%d. %s', i, item))
    end
    local choice = vim.fn.input('Please choose: ')
    return tonumber(choice) or 0
  else
    return vim.fn.inputlist(items)
  end
end

-- Set key mappings with mode support
function M.set_mapping(keys, rhs, mode)
  mode = mode or 'n'
  if type(keys) == 'string' then
    keys = { keys }
  end
  
  for _, key in ipairs(keys) do
    vim.keymap.set(mode, key, rhs, { buffer = true, silent = true })
  end
end

-- Print debug information if debug mode is enabled
function M.print_debug(info)
  if not config.debug then
    return
  end
  
  if type(info) == 'table' then
    if info.message then
      print('[DBUI Debug] ' .. info.message)
    end
    if info.command then
      print('[DBUI Debug] Command: ' .. info.command)
    end
    if info.lines then
      print('[DBUI Debug] Lines:')
      for i, line in ipairs(info.lines) do
        print('  ' .. i .. ': ' .. line)
      end
    end
  else
    print('[DBUI Debug] ' .. tostring(info))
  end
end

-- Check if buffer exists and is valid
function M.buf_exists(bufnr_or_name)
  if type(bufnr_or_name) == 'number' then
    return vim.api.nvim_buf_is_valid(bufnr_or_name)
  else
    return vim.fn.bufexists(bufnr_or_name) == 1
  end
end

-- Get buffer number by name
function M.get_bufnr(name)
  return vim.fn.bufnr(name)
end

-- Get window number by buffer number
function M.get_winnr(bufnr)
  return vim.fn.bufwinnr(bufnr)
end

-- Focus window by buffer name or number
function M.focus_window(bufnr_or_name)
  local bufnr = bufnr_or_name
  if type(bufnr_or_name) == 'string' then
    bufnr = vim.fn.bufnr(bufnr_or_name)
  end
  
  if bufnr == -1 then
    return false
  end
  
  local winnr = vim.fn.bufwinnr(bufnr)
  if winnr == -1 then
    return false
  end
  
  vim.cmd(winnr .. 'wincmd w')
  return true
end

-- Get visual selection
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  local start_row = start_pos[2]
  local start_col = start_pos[3]
  local end_row = end_pos[2]
  local end_col = end_pos[3]
  
  if start_row == end_row then
    local line = vim.fn.getline(start_row)
    return { line:sub(start_col, end_col) }
  else
    local lines = {}
    for i = start_row, end_row do
      local line = vim.fn.getline(i)
      if i == start_row then
        table.insert(lines, line:sub(start_col))
      elseif i == end_row then
        table.insert(lines, line:sub(1, end_col))
      else
        table.insert(lines, line)
      end
    end
    return lines
  end
end

-- Create a temporary file with given content
function M.create_temp_file(content, extension)
  extension = extension or 'sql'
  local temp_name = vim.fn.tempname() .. '.' .. extension
  
  if type(content) == 'table' then
    vim.fn.writefile(content, temp_name)
  else
    vim.fn.writefile(vim.split(content, '\n'), temp_name)
  end
  
  return temp_name
end

-- Check if a string is empty or only whitespace
function M.is_empty(str)
  return not str or str == '' or str:match('^%s*$')
end

-- Trim whitespace from string
function M.trim(str)
  return str:match('^%s*(.-)%s*$')
end

-- Deep copy a table
function M.deepcopy(t)
  if type(t) ~= 'table' then
    return t
  end
  
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = M.deepcopy(v)
  end
  
  return copy
end

return M 