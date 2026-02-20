-- ABOUTME: Tests for the dial module (watch face composition)
-- ABOUTME: Verifies full watch face rendering at known times

describe('dial', function()
  local dial = require('clock.dial')

  local noon = {
    hour = 12, minute = 0, second = 0,
    utc_hour = 17, utc_minute = 0,
    day = 15, wday = 'MON',
  }

  local three_oclock = {
    hour = 3, minute = 0, second = 0,
    utc_hour = 8, utc_minute = 0,
    day = 25, wday = 'THU',
  }

  describe('render', function()
    it('returns a grid with correct dimensions', function()
      local grid = dial.render(noon)
      assert.equals(dial.HEIGHT, #grid)
      assert.equals(dial.WIDTH, #grid[1])
    end)

    it('places center dot', function()
      local grid = dial.render(noon)
      assert.equals('●', grid[dial.CENTER_Y][dial.CENTER_X].char)
    end)
  end)

  describe('numerals', function()
    it('places 12 near top of dial', function()
      -- Use a time where no hands overlap the 12 position
      local time_info = {
        hour = 5, minute = 25, second = 40,
        utc_hour = 10, utc_minute = 25,
        day = 15, wday = 'TUE',
      }
      local grid = dial.render(time_info)
      local lines = require('clock.render').grid_to_lines(grid)
      local found = false
      for y = 1, math.floor(dial.HEIGHT / 3) do
        if lines[y]:find('12') then
          found = true
          break
        end
      end
      assert.is_true(found, 'numeral 12 not found in upper third')
    end)

    it('places 6 near bottom of dial', function()
      local grid = dial.render(noon)
      local lines = require('clock.render').grid_to_lines(grid)
      local found = false
      for y = math.floor(dial.HEIGHT * 2 / 3), dial.HEIGHT do
        if lines[y]:find('6') then
          found = true
          break
        end
      end
      assert.is_true(found, 'numeral 6 not found in lower third')
    end)

    it('places 3 on the right side', function()
      local grid = dial.render(noon)
      local lines = require('clock.render').grid_to_lines(grid)
      local found = false
      local mid_y_start = math.floor(dial.HEIGHT / 3)
      local mid_y_end = math.floor(dial.HEIGHT * 2 / 3)
      for y = mid_y_start, mid_y_end do
        local pos = lines[y]:find('3')
        if pos and pos > dial.CENTER_X then
          found = true
          break
        end
      end
      assert.is_true(found, 'numeral 3 not found on right side')
    end)

    it('places 9 on the left side', function()
      local grid = dial.render(noon)
      local lines = require('clock.render').grid_to_lines(grid)
      local found = false
      local mid_y_start = math.floor(dial.HEIGHT / 3)
      local mid_y_end = math.floor(dial.HEIGHT * 2 / 3)
      for y = mid_y_start, mid_y_end do
        local pos = lines[y]:find('9')
        if pos and pos < dial.CENTER_X then
          found = true
          break
        end
      end
      assert.is_true(found, 'numeral 9 not found on left side')
    end)

    it('has all 12 numerals on the dial', function()
      -- Use a time where hands cluster near 6-7 o'clock (not overlapping any numerals)
      local time_info = {
        hour = 6, minute = 33, second = 33,
        utc_hour = 11, utc_minute = 33,
        day = 1, wday = 'WED',
      }
      local grid = dial.render(time_info)
      local full_text = table.concat(require('clock.render').grid_to_lines(grid), '\n')
      for n = 1, 12 do
        assert.is_truthy(
          full_text:find(tostring(n)),
          'numeral ' .. n .. ' not found on dial'
        )
      end
    end)
  end)

  describe('date window', function()
    it('shows the day of month', function()
      local grid = dial.render(three_oclock)
      local lines = require('clock.render').grid_to_lines(grid)
      local found = false
      for _, line in ipairs(lines) do
        if line:find('25') then
          found = true
          break
        end
      end
      assert.is_true(found, 'date 25 not found on dial')
    end)

    it('zero-pads single digit days', function()
      local time_info = {
        hour = 12, minute = 0, second = 0,
        utc_hour = 17, utc_minute = 0,
        day = 5, wday = 'SUN',
      }
      local grid = dial.render(time_info)
      local lines = require('clock.render').grid_to_lines(grid)
      local found = false
      for _, line in ipairs(lines) do
        if line:find('05') then
          found = true
          break
        end
      end
      assert.is_true(found, 'zero-padded date 05 not found on dial')
    end)
  end)

  describe('brand text', function()
    it('shows plugin name on dial', function()
      local grid = dial.render(noon)
      local lines = require('clock.render').grid_to_lines(grid)
      local found = false
      for _, line in ipairs(lines) do
        if line:find('CLOCK') then
          found = true
          break
        end
      end
      assert.is_true(found, 'brand text not found on dial')
    end)
  end)

  describe('render_to_buffer', function()
    it('returns lines and highlights', function()
      local lines, highlights = dial.render_to_buffer(noon)
      assert.equals(dial.HEIGHT, #lines)
      assert.is_true(#highlights > 0)
      assert.is_true(type(lines[1]) == 'string')
      assert.is_true(highlights[1].hl_group ~= nil)
    end)
  end)

  describe('hands', function()
    it('renders different content at different times', function()
      local render = require('clock.render')
      local lines_noon = render.grid_to_lines(dial.render(noon))
      local lines_three = render.grid_to_lines(dial.render(three_oclock))
      -- The rendered output should differ between 12:00 and 3:00
      local differ = false
      for i = 1, #lines_noon do
        if lines_noon[i] ~= lines_three[i] then
          differ = true
          break
        end
      end
      assert.is_true(differ, 'dial should look different at different times')
    end)
  end)
end)
