-- ABOUTME: Composes the complete watch face from geometric primitives
-- ABOUTME: Renders hour markers, numerals, hands, date window, and brand text

local M = {}
local geometry = require('clock.geometry')
local render = require('clock.render')

M.WIDTH = 43
M.HEIGHT = 21
M.CENTER_X = 22
M.CENTER_Y = 11
M.DIAL_RADIUS = 9.5
M.CASE_RADIUS = 10

M.HOUR_HAND_LENGTH = 0.5
M.MINUTE_HAND_LENGTH = 0.75
M.SECOND_HAND_LENGTH = 0.85
M.GMT_HAND_LENGTH = 0.6

--- Draw minute markers as an even ring of dots between hour numerals
local function draw_minute_markers(grid)
  local used = {}

  -- Walk the circle in 1-degree steps for even cell coverage
  for deg = 0, 359 do
    -- Skip zones near hour numeral positions (±8° around each 30° mark)
    local nearest_hour = math.floor(deg / 30 + 0.5) * 30
    local dist_to_hour = math.abs(deg - nearest_hour)
    if dist_to_hour > 0 then
      dist_to_hour = math.min(dist_to_hour, 360 - dist_to_hour)
    end

    if dist_to_hour > 8 then
      local x, y = geometry.polar_to_cartesian(deg, M.DIAL_RADIUS * 0.85)
      local ax = math.floor(M.CENTER_X + x + 0.5)
      local ay = math.floor(M.CENTER_Y + y + 0.5)
      local key = ay * 1000 + ax

      if not used[key] and grid[ay] and grid[ay][ax] then
        grid[ay][ax] = { char = '·', hl_group = 'ClockTick' }
        used[key] = true
      end
    end
  end
end

--- Draw Arabic numerals at all 12 hour positions
local function draw_numerals(grid)
  local numerals = {
    [0]  = '12', [1] = '1', [2]  = '2', [3]  = '3',
    [4]  = '4',  [5] = '5', [6]  = '6', [7]  = '7',
    [8]  = '8',  [9] = '9', [10] = '10', [11] = '11',
  }

  for hour = 0, 11 do
    local text = numerals[hour]
    local angle = hour * 30
    local x, y = geometry.polar_to_cartesian(angle, M.DIAL_RADIUS * 0.8)
    local ax = math.floor(M.CENTER_X + x + 0.5) - math.floor(#text / 2)
    local ay = math.floor(M.CENTER_Y + y + 0.5)
    render.draw_text(grid, ax, ay, text, 'ClockNumeral')
  end
end

--- Center a string in a field of given width
local function center(s, w)
  local pad = w - #s
  local left = math.ceil(pad / 2)
  return string.rep(' ', left) .. s .. string.rep(' ', w - left - #s)
end

--- Draw the day/date complication window
local function draw_date_window(grid, day, wday)
  local width = 5
  local day_text = center(wday:sub(1, 3), width)
  local date_text = center(string.format('%02d', day), width)
  local wx = M.CENTER_X - math.floor(width / 2)
  local wy = M.CENTER_Y - 5

  -- Fill both rows with date highlight
  for dy = 0, 1 do
    for dx = 0, width - 1 do
      if grid[wy + dy] and grid[wy + dy][wx + dx] then
        grid[wy + dy][wx + dx] = { char = ' ', hl_group = 'ClockDate' }
      end
    end
  end

  -- Day of week on top, date below
  render.draw_text(grid, wx, wy, day_text, 'ClockDate')
  render.draw_text(grid, wx, wy + 1, date_text, 'ClockDate')
end

--- Draw brand text below center
local function draw_brand(grid)
  local brand = 'CLOCK.NVIM'
  local x = M.CENTER_X - math.floor(#brand / 2)
  local y = M.CENTER_Y + 4
  render.draw_text(grid, x, y, brand, 'ClockBrand')
end

--- Draw a single hand from center to endpoint
local function draw_hand(grid, angle, length_ratio, hl_group, style)
  local length = M.DIAL_RADIUS * length_ratio
  local ex, ey = geometry.polar_to_cartesian(angle, length)
  render.draw_line(
    grid,
    M.CENTER_X, M.CENTER_Y,
    M.CENTER_X + ex, M.CENTER_Y + ey,
    angle, hl_group, style
  )
end

--- Render the complete watch face
--- @param time_info table {hour, minute, second, utc_hour, utc_minute, day, wday}
--- @return table grid
function M.render(time_info)
  time_info = time_info or {
    hour = tonumber(os.date('%H')),
    minute = tonumber(os.date('%M')),
    second = tonumber(os.date('%S')),
    utc_hour = tonumber(os.date('!%H')),
    utc_minute = tonumber(os.date('!%M')),
    day = tonumber(os.date('%d')),
    wday = os.date('%a'):upper(),
  }

  local grid = render.create_grid(M.WIDTH, M.HEIGHT)

  -- Dial background (extend past bezel so smooth edge is outermost)
  local edge_radius = M.CASE_RADIUS + 0.5
  render.fill_circle(grid, M.CENTER_X, M.CENTER_Y, edge_radius, 'ClockDial')
  render.smooth_fill_edge(grid, M.CENTER_X, M.CENTER_Y, edge_radius, 'ClockEdge')

  -- Case outline (fully inside the smooth fill)
  render.draw_circle(grid, M.CENTER_X, M.CENTER_Y, M.CASE_RADIUS, '●', 'ClockCase')

  -- Minute markers and numerals
  draw_minute_markers(grid)
  draw_numerals(grid)

  -- Brand
  draw_brand(grid)

  local gmt_angle = geometry.gmt_angle(time_info.utc_hour, time_info.utc_minute)
  local hour_angle = geometry.hour_angle(time_info.hour, time_info.minute)
  local minute_angle = geometry.minute_angle(time_info.minute, time_info.second)
  local second_angle = geometry.second_angle(time_info.second)

  -- Hands (back to front: hour, minute, second, GMT on top)
  draw_hand(grid, hour_angle, M.HOUR_HAND_LENGTH, 'ClockHourHand', 'block')
  draw_hand(grid, minute_angle, M.MINUTE_HAND_LENGTH, 'ClockMinuteHand', 'thin')
  draw_hand(grid, second_angle, M.SECOND_HAND_LENGTH, 'ClockSecondHand', 'dot')
  draw_hand(grid, gmt_angle, M.GMT_HAND_LENGTH, 'ClockGmtHand', 'thin')

  -- Date window drawn last so it's always readable
  draw_date_window(grid, time_info.day, time_info.wday)

  -- Center dot (on top)
  grid[M.CENTER_Y][M.CENTER_X] = { char = '●', hl_group = 'ClockCase' }

  return grid
end

--- Render to buffer-ready format
--- @param time_info table|nil
--- @return string[] lines, table[] highlights
function M.render_to_buffer(time_info)
  local grid = M.render(time_info)
  return render.grid_to_lines(grid), render.grid_to_highlights(grid)
end

return M
