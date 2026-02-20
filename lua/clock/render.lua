-- ABOUTME: Renders geometric shapes into a 2D character grid
-- ABOUTME: Handles grid creation, shape drawing, and conversion to buffer output

local M = {}
local geometry = require('clock.geometry')

--- Create an empty grid filled with spaces
--- @param width number
--- @param height number
--- @return table grid[y][x] = {char=, hl_group=}
function M.create_grid(width, height)
  local grid = {}
  for y = 1, height do
    grid[y] = {}
    for x = 1, width do
      grid[y][x] = { char = ' ', hl_group = 'ClockBg' }
    end
  end
  return grid
end

--- Draw a circle outline on the grid
--- @param grid table
--- @param cx number center x
--- @param cy number center y
--- @param radius number
--- @param char string character to use for the edge
--- @param hl_group string highlight group
function M.draw_circle(grid, cx, cy, radius, char, hl_group)
  local height = #grid
  local width = #grid[1]

  for y = 1, height do
    for x = 1, width do
      local dx = (x - cx) / geometry.ASPECT_RATIO
      local dy = y - cy
      local dist = math.sqrt(dx * dx + dy * dy)
      if math.abs(dist - radius) < 0.5 then
        grid[y][x] = { char = char, hl_group = hl_group }
      end
    end
  end
end

--- Fill the interior of a circle with a highlight group
--- @param grid table
--- @param cx number center x
--- @param cy number center y
--- @param radius number
--- @param hl_group string highlight group
function M.fill_circle(grid, cx, cy, radius, hl_group)
  local height = #grid
  local width = #grid[1]

  for y = 1, height do
    for x = 1, width do
      if geometry.is_in_circle(x, y, cx, cy, radius) then
        grid[y][x].hl_group = hl_group
      end
    end
  end
end

--- Smooth the edge of a filled circle using half-block characters
--- @param grid table
--- @param cx number center x
--- @param cy number center y
--- @param radius number
--- @param edge_hl string highlight group (fg=fill color, bg inherited from window)
function M.smooth_fill_edge(grid, cx, cy, radius, edge_hl)
  local height = #grid
  local width = #grid[1]

  for y = 1, height do
    for x = 1, width do
      if geometry.is_in_circle(x, y, cx, cy, radius) then
        local above_in = y > 1 and geometry.is_in_circle(x, y - 1, cx, cy, radius)
        local below_in = y < height and geometry.is_in_circle(x, y + 1, cx, cy, radius)

        if not above_in and below_in then
          grid[y][x] = { char = '▄', hl_group = edge_hl }
        elseif above_in and not below_in then
          grid[y][x] = { char = '▀', hl_group = edge_hl }
        elseif not above_in and not below_in then
          grid[y][x] = { char = '▀', hl_group = edge_hl }
        else
          local left_in = x > 1 and geometry.is_in_circle(x - 1, y, cx, cy, radius)
          local right_in = x < width and geometry.is_in_circle(x + 1, y, cx, cy, radius)

          if not left_in and right_in then
            grid[y][x] = { char = '▐', hl_group = edge_hl }
          elseif left_in and not right_in then
            grid[y][x] = { char = '▌', hl_group = edge_hl }
          end
        end
      end
    end
  end
end

--- Draw a line on the grid using Bresenham
--- @param grid table
--- @param x0 number start x
--- @param y0 number start y
--- @param x1 number end x
--- @param y1 number end y
--- @param angle number angle of line (for character selection)
--- @param hl_group string highlight group
function M.draw_line(grid, x0, y0, x1, y1, angle, hl_group, style)
  local points = geometry.line_points(
    math.floor(x0 + 0.5),
    math.floor(y0 + 0.5),
    math.floor(x1 + 0.5),
    math.floor(y1 + 0.5)
  )

  local char = geometry.angle_to_char(angle, style)

  for _, p in ipairs(points) do
    if grid[p.y] and grid[p.y][p.x] then
      grid[p.y][p.x] = { char = char, hl_group = hl_group }
    end
  end
end

--- Iterate over UTF-8 characters in a string
--- @param str string
--- @return fun(): string|nil iterator returning one character per call
local function utf8_iter(str)
  local i = 1
  return function()
    if i > #str then return nil end
    local byte = str:byte(i)
    local len
    if byte < 128 then len = 1
    elseif byte < 224 then len = 2
    elseif byte < 240 then len = 3
    else len = 4
    end
    local char = str:sub(i, i + len - 1)
    i = i + len
    return char
  end
end

--- Draw text on the grid at a position (UTF-8 aware)
--- @param grid table
--- @param x number starting column
--- @param y number row
--- @param text string
--- @param hl_group string highlight group
function M.draw_text(grid, x, y, text, hl_group)
  if not grid[y] then return end

  local col = x
  for char in utf8_iter(text) do
    if grid[y][col] then
      grid[y][col] = { char = char, hl_group = hl_group }
    end
    col = col + 1
  end
end

--- Convert grid to array of strings for buffer output
--- @param grid table
--- @return string[]
function M.grid_to_lines(grid)
  local lines = {}
  for y = 1, #grid do
    local chars = {}
    for x = 1, #grid[y] do
      chars[x] = grid[y][x].char
    end
    lines[y] = table.concat(chars)
  end
  return lines
end

--- Convert grid to highlight spans for nvim_buf_add_highlight
--- Groups consecutive cells with the same highlight into spans
--- Uses byte offsets (not character positions) for multi-byte Unicode support
--- @param grid table
--- @return table[] list of {line=, col_start=, col_end=, hl_group=}
function M.grid_to_highlights(grid)
  local highlights = {}

  for y = 1, #grid do
    local current_hl = nil
    local start_byte = nil
    local byte_pos = 0

    for x = 1, #grid[y] do
      local cell = grid[y][x]
      local char_bytes = #cell.char

      if cell.hl_group ~= current_hl then
        if current_hl then
          table.insert(highlights, {
            line = y - 1,
            col_start = start_byte,
            col_end = byte_pos,
            hl_group = current_hl,
          })
        end
        current_hl = cell.hl_group
        start_byte = byte_pos
      end

      byte_pos = byte_pos + char_bytes
    end

    if current_hl then
      table.insert(highlights, {
        line = y - 1,
        col_start = start_byte,
        col_end = byte_pos,
        hl_group = current_hl,
      })
    end
  end

  return highlights
end

return M
