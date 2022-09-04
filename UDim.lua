local UDim = {}
---@class UDim
---@field new function Create a new UDim.
---@field Scale number The scale value for this UDim.
---@field Offset number The offset value for this UDim.

function UDim.new(scale, offset)
  return setmetatable(
    {
      Scale = scale or 0,
      Offset = offset or 0
    },
    UDim
  )
end

function UDim:__add(other)
  return UDim.new(self.Scale + other.Scale, self.Offset + other.Offset)
end

function UDim:__sub(other)
  return UDim.new(self.Scale - other.Scale, self.Offset - other.Offset)
end

return UDim