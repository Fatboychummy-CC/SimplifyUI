--- UDim2
-- @module[kind=Instance] UDim2

local Instance = require "Objects.Instance"
local UDim = require "Objects.UDim"
local expect = require "cc.expect".expect

Instance.Register("UDim2")

local UDim2 = {ClassName = "UDim2"} --- @type UDim2

--- Add two udim2s, used for __add operation.
local function Add(u1, u2)
  return UDim2.fromUDims(u1.X + u2.X, u1.Y + u2.Y)
end

--- Subtract two udim2s, used for __sub operation.
local function Sub(u1, u2)
  return UDim2.FromUDims(u1.X - u2.X, u1.Y - u2.Y)
end

--- Create a new UDim2. If you are calling `UDim2.new` directly, remove `instanceData` and shift the arguments left by one.
-- @tparam table|number instanceData Internal use, or the X-UDim scale for direct call.
-- @tparam number xScale The X-UDim scale for Internal use, or X-UDim Offset for direct call.
-- @tparam number xOffset The X-UDim offset for Internal use, or Y-UDim scale for direct call.
-- @tparam number xScale The Y-UDim scale for Internal use, or Y-UDim Offset for direct call.
-- @tparam number xOffset The Y-UDim offset for Internal use only.
-- @treturn UDim2 The new UDim2.
function UDim2.new(instanceData, xScale, xOffset, yScale, yOffset)
  expect(1, instanceData, "table", "number")
  expect(2, xScale, "number")
  expect(3, xOffset, "number")
  expect(4, yScale, "number")
  expect(5, yOffset, "number", "nil")

  -- creating UDim2 directly.
  if type(instanceData) == "number" then
    return Instance.new(UDim2, instanceData, xScale, xOffset, yScale, yOffset)
  end

  -- creating UDim via Instance.new
  instanceData.X = Instance.new(UDim, xScale, xOffset)
  instanceData.Y = Instance.new(UDim, yScale, yOffset)
  instanceData.Width = instanceData.X
  instanceData.Height = instanceData.Y

  -- create metatable instructions.
  local mt = getmetatable(instanceData)

  mt.__add = Add
  mt.__sub = Sub

  function instanceData._internal:Clone()
    return UDim2.fromUDims(self.X, self.Y)
  end

  instanceData.WRITING = nil
  return instanceData
end

--- Create a new UDim2, from two UDims. Unlike Roblox, you *must* use this constructor to construct a UDim2 using two UDims. This constructor copies values from the inserted UDims, it does not set `UDim2.X` directly to the `X` input.
-- @tparam UDim X The X-UDim.
-- @tparam UDim Y The Y-UDim.
-- @treturn UDim2 The new UDim2.
function UDim2.fromUDims(X, Y)
  expect(1, X, "table")
  expect(2, Y, "table")

  if not Instance.IsA(X, "UDim") then
    expect(1, X, "UDim") -- haha, nifty workaround for quick error messages.
  end
  if not Instance.IsA(Y, "UDim") then
    expect(2, Y, "UDim")
  end

  return Instance.new(UDim2, X.Scale, X.Offset, Y.Scale, Y.Offset)
end

--- Construct a new UDim2 using the given scalar coordinates. Equivalent to `UDim2.new(xScale, 0, yScale, 0)`
-- @tparam number xScale The X-UDim scale.
-- @tparam number yScale The Y-UDim scale.
-- @treturn UDim2 The new UDim2.
function UDim2.fromScale(xScale, yScale)
  expect(1, xScale, "number")
  expect(2, yScale, "number")

  return Instance.new(UDim2, xScale, 0, yScale, 0)
end

--- Construct a new UDim2 using the given scalar coordinates. Equivalent to `UDim2.new(0, xOffset, 0, yOffset)`
-- @tparam number xOffset The X-UDim offset.
-- @tparam number yOffset The Y-UDim offset.
-- @treturn UDim2 The new UDim2.
function UDim2.fromOffset(xOffset, yOffset)
  expect(1, xOffset, "number")
  expect(2, yOffset, "number")

  return Instance.new(UDim2, 0, xOffset, 0, yOffset)
end

local function lerp(x, y, alpha)
  return x + (y - x) * alpha
end

--- Returns a UDim2 interpolated linearly between this UDim2 and the given `goal`. The `alpha` value should be a number between 0 and 1. This function may not work appropriately.
-- @tparam UDim2 goal The goal UDim2 that the UDim2 should be interpolated against.
-- @tparam number alpha The alpha value between 0 and 1.
-- @treturn UDim2 A Udim2 linearly interpolated between, the input UDim2 and goal UDim2.
function UDim2:Lerp(goal, alpha)
  return Instance.new(
    UDim2,
    lerp(self.X.Scale , alpha),
    lerp(self.X.Offset, alpha),
    lerp(self.Y.Scale , alpha),
    lerp(self.Y.Offset, alpha)
  )
  -- I really hope this is how lerping is done
  -- pls be correct
end

return UDim2
