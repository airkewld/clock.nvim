-- ABOUTME: Tests for the geometry module (angles, circles, lines)
-- ABOUTME: Pure math tests — no Neovim APIs needed

describe('geometry', function()
  local geometry = require('clock.geometry')

  describe('hour_angle', function()
    it('returns 0 degrees for midnight', function()
      assert.equals(0, geometry.hour_angle(0, 0))
    end)

    it('returns 90 degrees for 3 AM', function()
      assert.equals(90, geometry.hour_angle(3, 0))
    end)

    it('returns 180 degrees for 6 AM', function()
      assert.equals(180, geometry.hour_angle(6, 0))
    end)

    it('returns 270 degrees for 9 AM', function()
      assert.equals(270, geometry.hour_angle(9, 0))
    end)

    it('treats noon same as midnight', function()
      assert.equals(0, geometry.hour_angle(12, 0))
    end)

    it('advances 0.5 degrees per minute', function()
      assert.equals(15, geometry.hour_angle(0, 30))
    end)
  end)

  describe('minute_angle', function()
    it('returns 0 at minute 0', function()
      assert.equals(0, geometry.minute_angle(0, 0))
    end)

    it('returns 90 at minute 15', function()
      assert.equals(90, geometry.minute_angle(15, 0))
    end)

    it('returns 180 at minute 30', function()
      assert.equals(180, geometry.minute_angle(30, 0))
    end)

    it('advances 0.1 degrees per second', function()
      assert.is_true(math.abs(geometry.minute_angle(1, 1) - 6.1) < 0.001)
    end)
  end)

  describe('second_angle', function()
    it('returns 0 at second 0', function()
      assert.equals(0, geometry.second_angle(0))
    end)

    it('returns 90 at second 15', function()
      assert.equals(90, geometry.second_angle(15))
    end)

    it('returns 180 at second 30', function()
      assert.equals(180, geometry.second_angle(30))
    end)

    it('returns 354 at second 59', function()
      assert.equals(354, geometry.second_angle(59))
    end)
  end)

  describe('gmt_angle', function()
    it('returns 0 at midnight UTC', function()
      assert.equals(0, geometry.gmt_angle(0, 0))
    end)

    it('returns 90 at 6 AM UTC', function()
      assert.equals(90, geometry.gmt_angle(6, 0))
    end)

    it('returns 180 at noon UTC', function()
      assert.equals(180, geometry.gmt_angle(12, 0))
    end)

    it('returns 270 at 6 PM UTC', function()
      assert.equals(270, geometry.gmt_angle(18, 0))
    end)

    it('advances 0.25 degrees per minute', function()
      assert.equals(15, geometry.gmt_angle(1, 0))
    end)
  end)

  describe('polar_to_cartesian', function()
    it('points up for 0 degrees', function()
      local x, y = geometry.polar_to_cartesian(0, 10)
      assert.is_true(math.abs(x) < 0.01)
      assert.is_true(math.abs(y - (-10)) < 0.01)
    end)

    it('points right for 90 degrees (aspect corrected)', function()
      local x, y = geometry.polar_to_cartesian(90, 10)
      assert.is_true(x > 15) -- doubled by aspect ratio
      assert.is_true(math.abs(y) < 0.01)
    end)

    it('points down for 180 degrees', function()
      local x, y = geometry.polar_to_cartesian(180, 10)
      assert.is_true(math.abs(x) < 0.01)
      assert.is_true(math.abs(y - 10) < 0.01)
    end)
  end)

  describe('is_in_circle', function()
    it('returns true for center point', function()
      assert.is_true(geometry.is_in_circle(10, 10, 10, 10, 5))
    end)

    it('returns false for point far outside', function()
      assert.is_false(geometry.is_in_circle(30, 10, 10, 10, 5))
    end)

    it('accounts for aspect ratio', function()
      -- x=20 is 10 chars from center at x=10, but only 5 visual units
      -- with radius 5, this should be on the edge (inside)
      assert.is_true(geometry.is_in_circle(20, 10, 10, 10, 5))
    end)
  end)

  describe('line_points', function()
    it('generates points for horizontal line', function()
      local points = geometry.line_points(0, 0, 5, 0)
      assert.equals(6, #points)
      assert.equals(0, points[1].x)
      assert.equals(5, points[#points].x)
    end)

    it('generates points for vertical line', function()
      local points = geometry.line_points(0, 0, 0, 5)
      assert.equals(6, #points)
      assert.equals(0, points[1].y)
      assert.equals(5, points[#points].y)
    end)

    it('generates points for single point', function()
      local points = geometry.line_points(3, 3, 3, 3)
      assert.equals(1, #points)
    end)
  end)

  describe('angle_to_char', function()
    it('returns vertical bar for 0 degrees', function()
      assert.equals('│', geometry.angle_to_char(0))
    end)

    it('returns horizontal bar for 90 degrees', function()
      assert.equals('─', geometry.angle_to_char(90))
    end)

    it('returns forward slash for ~45 degrees', function()
      assert.equals('/', geometry.angle_to_char(45))
    end)

    it('returns backslash for ~135 degrees', function()
      assert.equals('\\', geometry.angle_to_char(135))
    end)

    it('wraps around 180 degrees (vertical again)', function()
      assert.equals('│', geometry.angle_to_char(180))
    end)
  end)
end)
