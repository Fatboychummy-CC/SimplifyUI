--- Dual UDim, for X and Y direction.
-- This object stores two UDims, so differences can be held on X and Y axis.
-- @author fatboychummy
-- @type UDim2
-- @alias mt

local main = require "Objects.main"
local UDim = require "Objects.UDim"
local expect = require "cc.expect".expect

local UDim2 = {}

-- Create metatable.
local mt = {
  __index = function(self, k)
    if k ~= "X" and k ~= "Y" and k ~= "_classname" then
      main.readPrevent(k)
    end
    return rawget(k)
  end,
  __newIndex = function(self, k, v)
    if (k == "X" or k == "Y") and UDim.IsValid(v) then
      rawset(self, k, v)
    else
      main.writePrevent(k)
    end
  end
}

--- Add two UDim2 objects together.
-- @tparam {UDim2} dim1 LHS
-- @tparam {UDim2} dim2 RHS
-- @treturn {UDim2} LHS + RHS
function mt.__add(dim1, dim2)
  if not UDim2.IsValid(dim1) then
    error("LHS is not a valid UDim2.", 2)
  end
  if not UDim2.IsValid(dim2) then
    error("RHS is not a valid UDim2.", 2)
  end
  return UDim2.New(dim1.X + dim2.X, dim1.Y + dim2.Y)
end
--- Subtract a UDim2 from another UDim2.
-- @tparam {UDim2} dim1 LHS
-- @tparam {UDim2} dim2 RHS
-- @treturn {UDim2} LHS - RHS
function mt.__sub(dim1, dim2)
  if not UDim2.IsValid(dim1) then
    error("LHS is not a valid UDim2.", 2)
  end
  if not UDim2.IsValid(dim2) then
    error("RHS is not a valid UDim2.", 2)
  end
  return UDim2.New(dim1.X - dim2.X, dim1.Y - dim2.Y)
end

--- Create a new udim2, handles two udims or four numbers.
-- @tparam {number} xScale The x scale.
-- @tparam {number} xOffset The offset on the x axis.
-- @tparam {number} yScale The y scale.
-- @tparam {number} yOffset The offset on the y axis.
-- @treturn {UDim2} The UDim2 constructed from the offsets and scales supplied.
function UDim2.New(xScale, xOffset, yScale, yOffset)
  expect(1, xScale, "number")
  expect(2, xOffset, "number")
  expect(3, yScale, "number")
  expect(4, yOffset, "number")

  return setmetatable({
    X = UDim.New(xScale, xOffset),
    Y = UDim.New(yScale, yOffset),
    _classname = "UDim2"
  }, mt)
end

--- Create a new udim2, handles two udims or four numbers.
-- @tparam {UDim} dim1 The x axis UDim.
-- @tparam {UDim} dim2 The y axis UDim.
-- @treturn {UDim2} The UDim2 constructed from the supplied UDims.
function UDim2.FromUDims(dim1, dim2)
  expect(1, dim1, "table")
  expect(2, dim2, "table")

  if UDim.IsValid(dim1) and UDim.IsValid(dim2) then
    return setmetatable({
      X = UDim.New(dim1.Scale, dim1.Offset),
      Y = UDim.New(dim2.Scale, dim2.Offset),
      _classname = "UDim2"
    }, mt)
  end
  error("Invalid arguments given.", 2)
end

--- Create a new UDim2 from only the scales.
-- Equivalent to UDim2.new(xScale, 0, yScale, 0) .
-- @tparam {number} xScale The scale on the x axis.
-- @tparam {number} yScale The scale on the y axis.
-- @treturn {UDim2} The UDim2 constructed from the inputted scale values.
function UDim2.FromScale(xScale, yScale)
  return setmetatable({
    X = UDim.New(xScale, 0),
    Y = UDim.New(yScale, 0),
    _classname = "UDim2"
  }, mt)
end

--- Create a new UDim2 from only the offsets.
-- Equivalent to UDim2.new(0, xOffset, 0, yOffset) .
-- @tparam {number} xOffset The offset on the x axis.
-- @tparam {number} yOffset The offset on the y axis.
-- @treturn {UDim2} The UDim2 constructed from the inputted offset values.
function UDim2.FromOffset(xOffset, yOffset)
  return setmetatable({
    X = UDim.New(0, xOffset),
    Y = UDim.New(0, yOffset),
    _classname = "UDim2"
  }, mt)
end

--- Check if an object is valid.
-- @param object The object to be tested.
-- @treturn {boolean} true if the inputted object is a UDim2, false otherwise.
function UDim2.IsValid(object)
  return type(object) == "table" and object._classname == "UDim2"
end

return UDim2
