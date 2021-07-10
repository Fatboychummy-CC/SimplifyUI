--- Vector2
-- @module[kind=Instance] Vector2

local Instance = require "Objects.Instance"
local expect = require "cc.expect".expect


local Vector2 = {ClassName = "Vector2", _creatable = true, _properties = {X = 0, Y = 0}} --- @type Vector2
Instance.Register(Vector2)

--- Returns a Vector2 linearly interpolated between this Vector2 and v by the fraction alpha
-- @tparam v The vector to Lerp to.
-- @tparam alpha The alpha fraction.
-- @treturn Vector2 The lerp'd Vector2
function Vector2:Lerp(v, alpha)
  -- TODO: This
end

--- Returns a scalar dot product of the two vectors
-- @tparam v The vector to dot product with.
-- @treturn Vector2 The dot-product'd vector.
function Vector2:Dot(v)
  -- TODO: This
end

--- Returns the cross product of the two vectors
-- @tparam other The other vector.
-- @treturn Vector2 The cross-product'd vector.
function Vector2:Cross(other)
  -- TODO: This
end


local function Add(self, other)
  expect(1, self, "table")
  expect(2, other, "table", "number")

  if type(other) == "table" then
    return Instance.new(Vector2, self.X + other.X, self.Y + other.Y)
  end
  return Instance.new(Vector2, self.X + other, self.Y + other)
end
local function Sub(self, other)
  expect(1, self, "table")
  expect(2, other, "table", "number")

  if type(other) == "table" then
    return Instance.new(Vector2, self.X - other.X, self.Y - other.Y)
  end
  return Instance.new(Vector2, self.X - other, self.Y - other)
end
local function Mul(self, other)
  expect(1, self, "table")
  expect(2, other, "table", "number")

  if type(other) == "table" then
    return Instance.new(Vector2, self.X * other.X, self.Y * other.Y)
  end
  return Instance.new(Vector2, self.X * other, self.Y * other)
end
local function Div(self, other)
  expect(1, self, "table")
  expect(2, other, "table", "number")

  if type(other) == "table" then
    return Instance.new(Vector2, self.X / other.X, self.Y / other.Y)
  end
  return Instance.new(Vector2, self.X / other, self.Y / other)
end

--- Create a new Vector2. If you are calling `Vector2.new` directly, remove `instanceData` and shift the arguments left by one.
-- @tparam table|number instanceData Internal use, or the X value for direct call.
-- @tparam number x  X value, or the Y value for direct call.
-- @tparam number|nil y Y value, or dontCreateUnit on direct call.
-- @tparam boolean|nil dontCreateUnit For use in creating a vector2 -- allows to not create infinite repeating `.Unit` vectors.
-- @treturn Vector2 The new object.
function Vector2.new(instanceData, x, y, dontCreateUnit)
  expect(1, instanceData, "table", "number")
  expect(2, x, "number")
  expect(3, y, "number", "nil")
  expect(4, dontCreateUnit, "boolean", "nil")

  -- creating Vector2 directly.
  if type(instanceData) == "number" then
    return Instance.new(Vector2, instanceData, scale)
  end

  -- creating Vector2 via Instance.new
  instanceData.X = x
  instanceData.Y = y
  instanceData.Magnitude = 0
  instanceData.Unit = Instance.new(Vector2, 0, 0, true) -- oh fuck


  -- create metatable instructions.
  local mt = getmetatable(instanceData)

  mt.__add = Add
  mt.__sub = Sub
  mt.__mul = Mul
  mt.__div = Div

  function instanceData._internal:Clone()
    return Instance.new(Vector2, self.X, self.Y)
  end

  instanceData._WRITING = nil
  return instanceData
end

return Vector2
