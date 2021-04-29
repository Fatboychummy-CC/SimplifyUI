--- Universal Dimensions.
-- This object has an offset in pixels (characters) and a scale which is used heavily for positioning
-- @author fatboychummy
-- @type UDim
-- @alias mt

local main = require "Objects.main"
local BasicClass = require "Objects.BasicClass"
local expect = require "cc.expect".expect
local UDim = BasicClass.New("UDim", {
  --- Check if the input is a valid UDim.
  -- @param dim The object you wish to test.
  -- @treturn bool true if the object is a UDim, false otherwise.
  IsValid = function(dim)
    return type(dim) == "table" and dim.ClassName == "UDim"
  end
}, {}, true)

local mtInject = {}

--- Add two UDims.
-- @tparam UDim dim1 LHS
-- @tparam UDim dim2 RHS
-- @treturn UDim dim1 + dim2
function mtInject.__add(dim1, dim2)
  if not UDim.IsValid(dim1) then
    error("LHS is not a valid UDim.", 2)
  end
  if not UDim.IsValid(dim2) then
    error("RHS is not a valid UDim.", 2)
  end
  return UDim.New(dim1.Scale + dim2.Scale, dim1.Offset + dim2.Offset)
end

--- Subtract a UDim from another UDim.
-- @tparam UDim dim1 LHS
-- @tparam UDim dim2 RHS
-- @treturn UDim dim1 - dim2
function mtInject.__sub(dim1, dim2)
  if not UDim.IsValid(dim1) then
    error("LHS is not a valid UDim.", 2)
  end
  if not UDim.IsValid(dim2) then
    error("RHS is not a valid UDim.", 2)
  end
  return UDim.New(dim1.Scale - dim2.Scale, dim1.Offset - dim2.Offset)
end

function mtInject.__eq(dim1, dim2)
  if not UDim.IsValid(dim1) then
    error("LHS is not a valid UDim.", 2)
  end
  if not UDim.IsValid(dim2) then
    error("RHS is not a valid UDim.", 2)
  end
  return dim1.Scale == dim2.Scale and dim1.Offset == dim2.Offset
end

function mtInject.__tostring(self)
  return string.format("UDim: S=%.2f|O=%d", self.Scale, self.Offset)
end

UDim:New(function(scale, offset)
  expect(1, scale, "number")
  expect(2, offset, "number")

  local obj = BasicClass.New("UDim", {}, {Scale = scale, Offset = offset})
  local mt = getmetatable(obj)
  obj:InjectMT(mtInject)

  obj:SetPropertyChangedHandler(function(self, propertyName, newValue)
    if type(newValue) == "number" then
      return true
    end

    if propertyName == "Scale" or propertyName == "Offset" then
      return false, {"number"}, false
    end

    return true
  end)

  return obj
end)

return UDim
