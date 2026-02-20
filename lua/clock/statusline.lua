-- ABOUTME: Lualine status line component showing local and tracked GMT time
-- ABOUTME: Compact format for use in lualine sections

local M = {}

--- Format the GMT offset as a label (e.g. "UTC", "UTC+9", "UTC-5", "UTC+5.5")
--- @param offset number
--- @return string
local function gmt_label(offset)
  if offset == 0 then return 'UTC' end
  if offset % 1 == 0 then
    return string.format('UTC%+d', offset)
  end
  return string.format('UTC%+g', offset)
end

--- Returns formatted time string for lualine
--- @return string
function M.component()
  local config = require('clock').config
  local now = os.time()
  local local_time = os.date('%H:%M', now)
  local gmt_time = now + config.gmt_offset * 3600
  local tracked_time = os.date('!%H:%M', gmt_time)
  return string.format('%s (%s %s)', local_time, tracked_time, gmt_label(config.gmt_offset))
end

return M
