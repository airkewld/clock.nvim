-- ABOUTME: Main plugin entry point and public API
-- ABOUTME: Manages setup, floating window, timer, and commands

local M = {}
local dial = require('clock.dial')

M.win_id = nil
M.buf_id = nil
M.timer_id = nil
M.config = {
  gmt_offset = 0,
}

--- Define highlight groups for the watch face
local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  -- Dial face (deep green)
  hl(0, 'ClockDial', { bg = '#1a3a2a', fg = '#c8d8c8' })
  -- Case/bezel (silver)
  hl(0, 'ClockCase', { fg = '#888888', bg = '#1a3a2a' })
  -- Numerals (bright white on green)
  hl(0, 'ClockNumeral', { fg = '#ffffff', bg = '#1a3a2a', bold = true })
  -- Tick marks
  hl(0, 'ClockTick', { fg = '#c8d8c8', bg = '#1a3a2a' })
  -- Hour hand
  hl(0, 'ClockHourHand', { fg = '#ffffff', bg = '#1a3a2a', bold = true })
  -- Minute hand
  hl(0, 'ClockMinuteHand', { fg = '#ffffff', bg = '#1a3a2a', bold = true })
  -- Second hand
  hl(0, 'ClockSecondHand', { fg = '#dddddd', bg = '#1a3a2a' })
  -- GMT hand (red)
  hl(0, 'ClockGmtHand', { fg = '#cc3333', bg = '#1a3a2a', bold = true })
  -- Date window
  hl(0, 'ClockDate', { fg = '#000000', bg = '#ffffff', bold = true })
  -- Brand text
  hl(0, 'ClockBrand', { fg = '#668866', bg = '#1a3a2a' })
  -- Bezel markers
  hl(0, 'ClockBezel', { fg = '#778877', bg = '#1a3a2a' })
  -- Edge smoothing (half-block transition from dial to background)
  hl(0, 'ClockEdge', { fg = '#1a3a2a' })
  -- Background outside the dial (transparent, blends with editor)
  hl(0, 'ClockBg', { link = 'Normal' })
end

--- Create centered floating window
local function create_window()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'clock', { buf = buf })

  local ui = vim.api.nvim_list_uis()[1]
  local col = math.floor((ui.width - dial.WIDTH) / 2)
  local row = math.floor((ui.height - dial.HEIGHT) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = dial.WIDTH,
    height = dial.HEIGHT,
    col = col,
    row = row,
    style = 'minimal',
    border = 'none',
    focusable = true,
    zindex = 50,
  })

  vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:ClockBg', { win = win })
  vim.api.nvim_set_option_value('cursorline', false, { win = win })
  vim.api.nvim_set_option_value('number', false, { win = win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = win })

  -- Close keymaps
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, function() M.hide() end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
  end

  M.buf_id = buf
  M.win_id = win
end

--- Build time_info with configured GMT offset applied
local function build_time_info()
  local now = os.time()
  local gmt_time = now + M.config.gmt_offset * 3600
  local gmt = os.date('!*t', gmt_time)
  return {
    hour = tonumber(os.date('%H', now)),
    minute = tonumber(os.date('%M', now)),
    second = tonumber(os.date('%S', now)),
    utc_hour = gmt.hour,
    utc_minute = gmt.min,
    day = tonumber(os.date('%d', now)),
    wday = os.date('%a', now):upper(),
  }
end

--- Update the buffer with the current watch face
local function update_display()
  if not M.buf_id or not vim.api.nvim_buf_is_valid(M.buf_id) then
    M.stop_timer()
    return
  end

  local lines, highlights = dial.render_to_buffer(build_time_info())

  vim.api.nvim_set_option_value('modifiable', true, { buf = M.buf_id })
  vim.api.nvim_buf_set_lines(M.buf_id, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = M.buf_id })

  vim.api.nvim_buf_clear_namespace(M.buf_id, -1, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      M.buf_id, -1, hl.hl_group, hl.line, hl.col_start, hl.col_end
    )
  end
end

--- Start the update timer
local function start_timer()
  M.stop_timer()
  M.timer_id = vim.fn.timer_start(1000, function()
    vim.schedule(update_display)
  end, { ['repeat'] = -1 })
end

--- Stop the update timer
function M.stop_timer()
  if M.timer_id then
    vim.fn.timer_stop(M.timer_id)
    M.timer_id = nil
  end
end

--- Show the watch face
function M.show()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    return
  end

  create_window()
  update_display()
  start_timer()
end

--- Hide the watch face
function M.hide()
  M.stop_timer()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_win_close(M.win_id, true)
  end
  M.win_id = nil
  M.buf_id = nil
end

--- Toggle the watch face
function M.toggle()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    M.hide()
  else
    M.show()
  end
end

--- Plugin setup
--- @param opts table|nil { gmt_offset = number }
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  setup_highlights()

  vim.api.nvim_create_user_command('Clock', function()
    M.toggle()
  end, {})

  vim.keymap.set('n', '<leader>ck', function()
    M.toggle()
  end, {
    noremap = true,
    silent = true,
    desc = 'Toggle analog clock',
  })
end

return M
