--- Dual UDim, for X and Y direction.
-- This object stores two UDims, so differences can be held on X and Y axis.
-- @author fatboychummy
-- @type UDim2
-- @alias mt

local main = require "Objects.main"
local UDim = require "Objects.UDim"
local BasicClass = require "Objects.BasicClass"
local expect = require "cc.expect".expect

local New

local UDim2 = BasicClass.New("UDim2", {
  --- Check if the input is a valid UDim.
  -- @param dim The object you wish to test.
  -- @treturn bool true if the object is a UDim, false otherwise.
  IsValid = function(dim)
    return type(dim) == "table" and dim.ClassName == "UDim2"
  end,

  --- Create a new udim2, handles two udims
  -- @tparam UDim dim1 The x axis UDim.
  -- @tparam UDim dim2 The y axis UDim.
  -- @treturn UDim2 The UDim2 constructed from the supplied UDims.
  FromUDims = function(dim1, dim2)
    expect(1, dim1, "table")
    expect(2, dim2, "table")

    if UDim.IsValid(dim1) and UDim.IsValid(dim2) then
      return New(dim1.Scale, dim1.Offset, dim2.Scale, dim2.Offset)
    end
    error("Invalid arguments given.", 2)
  end,

  --- Create a new UDim2 from only the scales.
  -- Equivalent to UDim2.new(xScale, 0, yScale, 0) .
  -- @tparam number xScale The scale on the x axis.
  -- @tparam number yScale The scale on the y axis.
  -- @treturn UDim2 The UDim2 constructed from the inputted scale values.
  FromScale = function(xScale, yScale)
    return New(xScale, 0, yScale, 0)
  end,

  --- Create a new UDim2 from only the offsets.
  -- Equivalent to UDim2.new(0, xOffset, 0, yOffset) .
  -- @tparam number xOffset The offset on the x axis.
  -- @tparam number yOffset The offset on the y axis.
  -- @treturn UDim2 The UDim2 constructed from the inputted offset values.
  FromOffset = function(xOffset, yOffset)
    return New(0, xOffset, 0, yOffset)
  end
}, {}, true)

local mtInject = {}

function mtInject.__eq(dim1, dim2)
  if not UDim2.IsValid(dim1) then
    error("LHS is not a valid UDim2.", 2)
  end
  if not UDim2.IsValid(dim2) then
    error("RHS is not a valid UDim2.", 2)
  end

  return dim1.X == dim2.X and dim1.Y == dim2.Y
end

--- Add two UDim2 objects together.
-- @tparam UDim2 dim1 LHS
-- @tparam UDim2 dim2 RHS
-- @treturn UDim2 LHS + RHS
function mtInject.__add(dim1, dim2)
  if not UDim2.IsValid(dim1) then
    error("LHS is not a valid UDim2.", 2)
  end
  if not UDim2.IsValid(dim2) then
    error("RHS is not a valid UDim2.", 2)
  end
  return UDim2.FromUDims(dim1.X + dim2.X, dim1.Y + dim2.Y)
end

--- Subtract a UDim2 from another UDim2.
-- @tparam UDim2 dim1 LHS
-- @tparam UDim2 dim2 RHS
-- @treturn UDim2 LHS - RHS
function mtInject.__sub(dim1, dim2)
  if not UDim2.IsValid(dim1) then
    error("LHS is not a valid UDim2.", 2)
  end
  if not UDim2.IsValid(dim2) then
    error("RHS is not a valid UDim2.", 2)
  end
  return UDim2.FromUDims(dim1.X - dim2.X, dim1.Y - dim2.Y)
end

function mtInject.__tostring(self)
  return string.format("UDim2: || X=%s || Y=%s ||", tostring(self.X), tostring(self.Y))
end


--- Create a new udim2
-- @tparam number xScale The x scale.
-- @tparam number xOffset The offset on the x axis.
-- @tparam number yScale The y scale.
-- @tparam number yOffset The offset on the y axis.
-- @treturn UDim2 The UDim2 constructed from the offsets and scales supplied.
New = function(xScale, xOffset, yScale, yOffset)
  expect(1, xScale, "number")
  expect(2, xOffset, "number")
  expect(3, yScale, "number")
  expect(4, yOffset, "number")

  local obj = BasicClass.New("UDim2", {}, {
    X = UDim.New(xScale, xOffset),
    Y = UDim.New(yScale, yOffset)
  })
  local proxy = obj:GetProxy()
  obj:InjectMT(mtInject)
  obj:SetPropertyChangedHandler(function(self, propertyName, newValue)
    if UDim.IsValid(newValue) then
      return true
    end

    if propertyName ~= "X" and propertyName ~= "Y" then
      return true
    end

    return false, {"UDim"}, true
  end)

  return obj
end

UDim2:New(New)

return UDim2
