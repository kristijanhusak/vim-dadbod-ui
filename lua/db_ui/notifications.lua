local config = require('db_ui.config')

local M = {}

-- Check if nvim-notify is available
local function has_nvim_notify()
  return config.use_nvim_notify and pcall(require, 'notify')
end

-- Get notification options with defaults
local function get_notify_opts(opts)
  opts = opts or {}
  return {
    title = opts.title or 'DB UI',
    timeout = opts.delay or opts.timeout or 5000,
    width = opts.width or config.notification_width,
    level = opts.level or vim.log.levels.INFO,
    echo = opts.echo or config.force_echo_notifications
  }
end

-- Core notification function
local function notify(message, level, opts)
  opts = get_notify_opts(opts)
  opts.level = level
  
  -- Convert message to string if it's a table
  if type(message) == 'table' then
    message = table.concat(message, '\n')
  end
  
  -- Use nvim-notify if available and enabled
  if has_nvim_notify() and not opts.echo then
    local notify_fn = require('notify')
    notify_fn(message, level, {
      title = opts.title,
      timeout = opts.timeout,
      width = opts.width
    })
    return
  end
  
  -- Fallback to vim echo
  local level_names = {
    [vim.log.levels.ERROR] = 'Error',
    [vim.log.levels.WARN] = 'Warning', 
    [vim.log.levels.INFO] = 'Info',
    [vim.log.levels.DEBUG] = 'Debug'
  }
  
  local level_name = level_names[level] or 'Info'
  local full_message = string.format('[%s] %s', level_name, message)
  
  -- Use appropriate vim highlighting
  if level == vim.log.levels.ERROR then
    vim.api.nvim_err_writeln(full_message)
  elseif level == vim.log.levels.WARN then
    vim.api.nvim_echo({{full_message, 'WarningMsg'}}, true, {})
  else
    vim.api.nvim_echo({{full_message, 'None'}}, true, {})
  end
end

-- Info notification
function M.info(message, opts)
  if config.disable_info_notifications then
    return
  end
  notify(message, vim.log.levels.INFO, opts)
end

-- Warning notification
function M.warning(message, opts)
  notify(message, vim.log.levels.WARN, opts)
end

-- Error notification
function M.error(message, opts)
  notify(message, vim.log.levels.ERROR, opts)
end

-- Debug notification (only shown if debug is enabled)
function M.debug(message, opts)
  if config.debug then
    notify(message, vim.log.levels.DEBUG, opts)
  end
end

-- Success notification (alias for info with success styling)
function M.success(message, opts)
  opts = opts or {}
  opts.title = opts.title or 'DB UI - Success'
  M.info(message, opts)
end

-- Progress notification (for async operations)
function M.progress(message, opts)
  if config.disable_progress_bar then
    return
  end
  
  opts = opts or {}
  opts.timeout = opts.timeout or 0  -- Don't auto-dismiss progress notifications
  M.info(message, opts)
end

-- Clear all notifications (if using nvim-notify)
function M.clear()
  if has_nvim_notify() then
    require('notify').dismiss({ silent = true, pending = true })
  end
end

return M 