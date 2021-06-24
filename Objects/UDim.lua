--- UDim
-- @module[kind=Instance] UDim

local Instance = require "Objects.Instance"
local expect = require "cc.expect".expect


local UDim = {ClassName = "UDim"} --- @type UDim
Instance.Register(UDim)

--- Add two udims, used for __add operation.
local function Add(u1, u2)
  return Instance.new(UDim, u1.Scale + u2.Scale, u1.Offset + u2.Offset)
end

--- Subtract two udims, used for __sub operation.
local function Sub(u1, u2)
  return Instance.new(UDim, u1.Scale - u2.Scale, u1.Offset - u2.Offset)
end

--- Create a new UDim. If you are calling `UDim.new` directly, remove `instanceData` and shift the arguments left by one.
-- @tparam table|number instanceData Internal use, or the scale for direct call.
-- @tparam number scale scale Internal use, or the offset for direct call.
-- @tparam number|nil offset Internal use only.
-- @treturn UDim The new object.
function UDim.new(instanceData, scale, offset)
  expect(1, instanceData, "table", "number")
  expect(2, scale, "number")
  expect(3, offset, "number", "nil")

  -- creating UDim directly.
  if type(instanceData) == "number" then
    return Instance.new(UDim, instanceData, scale)
  end

  -- creating UDim via Instance.new
  instanceData.Scale = scale
  instanceData.Offset = offset

  -- create metatable instructions.
  local mt = getmetatable(instanceData)

  mt.__add = Add
  mt.__sub = Sub

  function instanceData._internal:Clone()
    return Instance.new(UDim, self.Scale, self.Offset)
  end

  instanceData.WRITING = nil
  return instanceData
end

return UDim
