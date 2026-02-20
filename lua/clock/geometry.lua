-- ABOUTME: Geometric calculations for watch face rendering
-- ABOUTME: Pure math functions for angles, circles, and line rasterization

local M = {}

M.ASPECT_RATIO = 2.0

--- Calculate angle in degrees for the hour hand
--- @param hour number 0-23
--- @param minute number 0-59
--- @return number degrees (0-360, 0 = 12 o'clock, clockwise)
function M.hour_angle(hour, minute)
  local h = hour % 12
  return (h * 30) + (minute * 0.5)
end

--- Calculate angle in degrees for the minute hand
--- @param minute number 0-59
--- @param second number 0-59
--- @return number degrees (0-360)
function M.minute_angle(minute, second)
  return (minute * 6) + (second * 0.1)
end

--- Calculate angle in degrees for the second hand
--- @param second number 0-59
--- @return number degrees (0-360)
function M.second_angle(second)
  return second * 6
end

--- Calculate angle in degrees for the GMT hand (24-hour rotation)
--- @param hour number 0-23 (UTC)
--- @param minute number 0-59
--- @return number degrees (0-360)
function M.gmt_angle(hour, minute)
  return (hour * 15) + (minute * 0.25)
end

--- Convert polar coordinates to cartesian, correcting for terminal aspect ratio
--- @param angle number degrees (0 = 12 o'clock, clockwise)
--- @param radius number distance from center
--- @return number x, number y
function M.polar_to_cartesian(angle, radius)
  local rad = math.rad(angle - 90) -- -90 so 0° points up
  local x = radius * math.cos(rad) * M.ASPECT_RATIO
  local y = radius * math.sin(rad)
  return x, y
end

--- Check if a point is inside a circle, accounting for aspect ratio
--- @param x number
--- @param y number
--- @param cx number center x
--- @param cy number center y
--- @param radius number
--- @return boolean
function M.is_in_circle(x, y, cx, cy, radius)
  local dx = (x - cx) / M.ASPECT_RATIO
  local dy = y - cy
  return (dx * dx + dy * dy) <= (radius * radius)
end

--- Bresenham line algorithm — returns list of points from (x0,y0) to (x1,y1)
--- @param x0 number
--- @param y0 number
--- @param x1 number
--- @param y1 number
--- @return table[] list of {x=, y=} points
function M.line_points(x0, y0, x1, y1)
  local points = {}
  local dx = math.abs(x1 - x0)
  local dy = math.abs(y1 - y0)
  local sx = x0 < x1 and 1 or -1
  local sy = y0 < y1 and 1 or -1
  local err = dx - dy

  while true do
    table.insert(points, { x = x0, y = y0 })
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 > -dy then
      err = err - dy
      x0 = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0 = y0 + sy
    end
  end

  return points
end

--- Hand character styles for visual distinction
M.hand_styles = {
  thin  = { '│', '/', '─', '\\' },
  block = { '█', '█', '█', '█' },
  dot   = { '•', '•', '•', '•' },
}

--- Choose the best character to represent a line at the given angle
--- @param angle number degrees
--- @param style string|nil hand style ('thin', 'block', 'dot'); defaults to 'thin'
--- @return string single character
function M.angle_to_char(angle, style)
  local chars = M.hand_styles[style or 'thin']
  local a = angle % 180
  if a < 22.5 or a >= 157.5 then
    return chars[1]
  elseif a < 67.5 then
    return chars[2]
  elseif a < 112.5 then
    return chars[3]
  else
    return chars[4]
  end
end

return M
