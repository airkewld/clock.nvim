-- ABOUTME: Tests for the render module (grid operations)
-- ABOUTME: Verifies grid creation, circle/line/text drawing, and output conversion

describe('render', function()
  local render = require('clock.render')

  describe('create_grid', function()
    it('creates grid with correct dimensions', function()
      local grid = render.create_grid(10, 5)
      assert.equals(5, #grid)
      assert.equals(10, #grid[1])
    end)

    it('fills cells with spaces and default highlight', function()
      local grid = render.create_grid(3, 2)
      assert.equals(' ', grid[1][1].char)
      assert.equals('ClockBg', grid[1][1].hl_group)
    end)
  end)

  describe('draw_text', function()
    it('places characters at correct positions', function()
      local grid = render.create_grid(10, 3)
      render.draw_text(grid, 2, 2, 'AB', 'ClockNumeral')
      assert.equals('A', grid[2][2].char)
      assert.equals('B', grid[2][3].char)
      assert.equals('ClockNumeral', grid[2][2].hl_group)
    end)

    it('does not overflow grid bounds', function()
      local grid = render.create_grid(5, 3)
      render.draw_text(grid, 4, 2, 'ABC', 'ClockNumeral')
      assert.equals('A', grid[2][4].char)
      assert.equals('B', grid[2][5].char)
      -- 'C' would be at column 6 which is out of bounds
      assert.equals(' ', grid[2][3].char) -- unaffected
    end)

    it('ignores out-of-bounds row', function()
      local grid = render.create_grid(5, 3)
      -- should not error
      render.draw_text(grid, 1, 10, 'test', 'ClockNumeral')
    end)

    it('handles multi-byte UTF-8 characters', function()
      local grid = render.create_grid(10, 3)
      render.draw_text(grid, 2, 2, '┌──┐', 'ClockDate')
      assert.equals('┌', grid[2][2].char)
      assert.equals('─', grid[2][3].char)
      assert.equals('─', grid[2][4].char)
      assert.equals('┐', grid[2][5].char)
      -- Each cell stores exactly one UTF-8 character
      assert.equals(3, #grid[2][2].char) -- ┌ is 3 bytes
      -- Only 4 cells affected, next cell untouched
      assert.equals(' ', grid[2][6].char)
    end)
  end)

  describe('draw_line', function()
    it('draws a horizontal line', function()
      local grid = render.create_grid(10, 5)
      render.draw_line(grid, 2, 3, 6, 3, 90, 'ClockHourHand')
      assert.equals('─', grid[3][2].char)
      assert.equals('─', grid[3][4].char)
      assert.equals('─', grid[3][6].char)
      assert.equals('ClockHourHand', grid[3][4].hl_group)
    end)

    it('draws a vertical line', function()
      local grid = render.create_grid(10, 5)
      render.draw_line(grid, 5, 1, 5, 4, 0, 'ClockMinuteHand')
      assert.equals('│', grid[1][5].char)
      assert.equals('│', grid[2][5].char)
      assert.equals('│', grid[4][5].char)
    end)
  end)

  describe('fill_circle', function()
    it('fills interior points', function()
      local grid = render.create_grid(21, 11)
      render.fill_circle(grid, 11, 6, 5, 'ClockDial')
      -- Center should be filled
      assert.equals('ClockDial', grid[6][11].hl_group)
      -- A point well inside should be filled
      assert.equals('ClockDial', grid[6][13].hl_group)
    end)
  end)

  describe('draw_circle', function()
    it('places characters on the circle edge', function()
      local grid = render.create_grid(21, 11)
      render.draw_circle(grid, 11, 6, 5, '●', 'ClockCase')
      -- Top of circle (y = 6-5 = 1)
      local found_top = false
      for x = 1, 21 do
        if grid[1][x].char == '●' then
          found_top = true
          break
        end
      end
      assert.is_true(found_top)
    end)
  end)

  describe('grid_to_lines', function()
    it('converts grid to array of strings', function()
      local grid = render.create_grid(3, 2)
      grid[1][1].char = 'A'
      grid[1][2].char = 'B'
      grid[2][3].char = 'C'
      local lines = render.grid_to_lines(grid)
      assert.equals(2, #lines)
      assert.equals('AB ', lines[1])
      assert.equals('  C', lines[2])
    end)
  end)

  describe('grid_to_highlights', function()
    it('groups consecutive cells with same highlight', function()
      local grid = render.create_grid(4, 1)
      grid[1][1].hl_group = 'A'
      grid[1][2].hl_group = 'A'
      grid[1][3].hl_group = 'B'
      grid[1][4].hl_group = 'B'
      local hls = render.grid_to_highlights(grid)
      assert.equals(2, #hls)
      assert.equals('A', hls[1].hl_group)
      assert.equals(0, hls[1].line)
      assert.equals(0, hls[1].col_start)
      assert.equals(2, hls[1].col_end)
      assert.equals('B', hls[2].hl_group)
      assert.equals(2, hls[2].col_start)
      assert.equals(4, hls[2].col_end)
    end)

    it('handles multiple rows', function()
      local grid = render.create_grid(2, 2)
      grid[1][1].hl_group = 'X'
      grid[1][2].hl_group = 'X'
      grid[2][1].hl_group = 'Y'
      grid[2][2].hl_group = 'Y'
      local hls = render.grid_to_highlights(grid)
      assert.equals(2, #hls)
      assert.equals(0, hls[1].line)
      assert.equals(1, hls[2].line)
    end)

    it('uses byte offsets for multi-byte characters', function()
      local grid = render.create_grid(3, 1)
      grid[1][1].char = '●'  -- 3 bytes in UTF-8
      grid[1][1].hl_group = 'A'
      grid[1][2].char = ' '  -- 1 byte
      grid[1][2].hl_group = 'B'
      grid[1][3].char = '·'  -- 2 bytes in UTF-8
      grid[1][3].hl_group = 'B'
      local hls = render.grid_to_highlights(grid)
      assert.equals(2, #hls)
      -- First span: '●' = 3 bytes
      assert.equals(0, hls[1].col_start)
      assert.equals(3, hls[1].col_end)
      -- Second span: ' ' + '·' = 1 + 2 = 3 bytes
      assert.equals(3, hls[2].col_start)
      assert.equals(6, hls[2].col_end)
    end)
  end)
end)
