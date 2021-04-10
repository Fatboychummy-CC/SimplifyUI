--- Universal Dimensions.
-- This object has an offset in pixels (characters) and a scale which is used heavily for positioning
-- @author fatboychummy
-- @type UDim
-- @alias mt

local main = require "Objects.main"
local expect = require "cc.expect".expect
local UDim = {}

local mt = {
  __index = function(self, k)
    if k ~= "Scale" and k ~= "Offset" and k ~= "_classname" then
      main.readPrevent(k)
    end
    return rawget(self, k)
  end,
  __newIndex = function(self, k, v)
    if k == "Scale" then
      rawset(self, k, v)
    elseif k == "Offset" then
      rawset(self, k, v)
    else main.writePrevent(k) end
  end,
  __tostring = function(self)
    return string.format("UDim: S=%.2f|O=%d", self.Scale, self.Offset)
  end
}

--- Add two UDims.
-- @tparam UDim dim1 LHS
-- @tparam UDim dim2 RHS
-- @treturn UDim dim1 + dim2
function mt.__add(dim1, dim2)
  if not UDim.IsValid(dim1) then
    error("LHS is not a valid UDim.", 2)
  end
  if not UDim.IsValid(dim2) then
    error("RHS is not a valid UDim.", 2)
  end
  return UDim.new(main.clamp(dim1.Scale + dim2.Scale), dim1.Offset + dim2.Offset)
end

--- Subtract a UDim from another UDim.
-- @tparam UDim dim1 LHS
-- @tparam UDim dim2 RHS
-- @treturn UDim dim1 - dim2
function mt.__sub(dim1, dim2)
  if not UDim.IsValid(dim1) then
    error("LHS is not a valid UDim.", 2)
  end
  if not UDim.IsValid(dim2) then
    error("RHS is not a valid UDim.", 2)
  end
  return UDim.new(main.clamp(dim1.Scale - dim2.Scale), dim1.Offset - dim2.Offset)
end

--- Create a new UDim.
-- @tparam number scale The scale of the UDim ([usually] between 0 and 1).
-- @tparam number offset The offset of the UDim (Integer).
-- @treturn UDim The new UDim.
function UDim.New(scale, offset)
  expect(1, scale, "number")
  expect(2, offset, "number")

  return setmetatable({Scale = scale, Offset = offset, _classname = "UDim"}, mt)
end

--- Check if the input is a valid UDim.
-- @param dim The object you wish to test.
-- @treturn bool true if the object is a UDim, false otherwise.
function UDim.IsValid(dim)
  return type(dim) == "table" and dim._classname == "UDim"
end

return UDim
