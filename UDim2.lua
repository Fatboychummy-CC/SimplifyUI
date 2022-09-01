local expect = require "cc.expect".expect

local UDim = require "UDim"
local Utilities = require "Utilities"

local UDim2 = {}

function UDim2.new(scale_x, offset_x, scale_y, offset_y)
  local obj
  if type(scale_x) == "number" then
    expect(1, scale_x,  "number", "nil")
    expect(2, offset_x, "number", "nil")
    expect(3, scale_y,  "number", "nil")
    expect(4, offset_y, "number", "nil")

    obj = {
      X = UDim.new(scale_x, offset_x),
      Y = UDim.new(scale_y, offset_y)
    }
  elseif type(scale_x) == "table" then
    expect(1, scale_x, "table")
    expect(2, offset_x, "table")

    if not scale_x.__IsUDim then
      error("Bad argument #1: Expected UDim", 2)
    end
    if not offset_x.__IsUDim then
      error("Bad argument #2: Expected UDim", 2)
    end

    obj = {
      X = UDim.new(scale_x.Scale, scale_x.Offset),
      Y = UDim.new(offset_x.Scale, offset_x.Offset)
    }
  end

  obj.Width = obj.X
  obj.Height = obj.Y
  obj.__IsUDim2 = true

  return setmetatable(obj, UDim2)
end

function UDim2.fromScale(scale_x, scale_y)
  expect(1, scale_x, "number")
  expect(2, scale_y, "number")

  return UDim2.new(scale_x, 0, scale_y, 0)
end

function UDim2.fromOffset(offset_x, offset_y)
  expect(1, offset_x, "number")
  expect(2, offset_y, "number")

  return UDim2.new(0, offset_x, 0, offset_y)
end

function UDim2:Lerp(goal, alpha)
  expect(1, goal, "table")
  if not goal.__IsUDim2 then
    error("Bad argument #1: Expected UDim2", 2)
  end
  expect(2, alpha, "number")

  return UDim2.new(
    Utilities.Lerp(self.X.Scale,  goal.X.Scale,  alpha),
    Utilities.Lerp(self.X.Offset, goal.X.Offset, alpha),
    Utilities.Lerp(self.Y.Scale,  goal.Y.Scale,  alpha),
    Utilities.Lerp(self.Y.Offset, goal.Y.Offset, alpha)
  )
end

function UDim2:__add(other)
  return UDim2.new(self.X + other.X, self.Y + other.Y)
end

function UDim2:__sub(other)
  return UDim2.new(self.X - other.X, self.Y - other.Y)
end

return UDim2