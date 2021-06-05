--- Creates basic classes with integrations for events.
-- @author fatboychummy
-- @type Object

local e = require "cc.expect"
local TE = require "Objects.Util.TableExtensions"
local expect, field = e.expect, e.field
local lastID = 0

local function incLastID()
  lastID = lastID + 1
end

local Instance = {
  Classes = {},
  Nil = {}
}

local instanceMT = {}

-- Writeable if:
-- 1. In writeable table
-- 2. Type is a class or coreluatype in AllowedTypes, or type is Instance and Instance is in AllowedTypes
function instanceMT.__newindex = function(self, key, newValue)
  -- if we're trying to write to a readonly member, fail.
  if type(self._proxy.readOnly[key]) ~= "nil" then
    error(string.format("%s is a read-only member of %s", key, self.ClassName), 2)
  end

  -- if we're trying to write to a writeable member that exists...
  if type(self._proxy.writeable[key]) ~= "nil" then
    -- get the member information
    local t = self._proxy.writeable[key]
    local newType = type(newValue)

    -- if we're using a base lua type and it's in the table of allowed types, great!
    -- also, if we're looking for an instance of any type and passed an instance, great!
    if TE.find(t.AllowedTypes, newType) or newType == "table" and newType.Instance and TE.find(t.AllowedTypes, "Instance") then
      self._proxy.writeable[key].Value = newValue
      return
    end

    -- if none of the above, fail.
    expect(3, newValue, table.unpack(t.AllowedTypes))
  end

  -- member does not exist.
  error(string.format("%s is not a valid member of %s", key, self.ClassName), 2)
end

function instanceMT.__index = function(self, key)
  -- If it's in the readonly portion, return it.
  if type(self._proxy.readOnly[key]) ~= "nil" then return self._proxy.readOnly[key].Value end
  -- If its in the writeable portion, return it.
  if type(self._proxy.writeable[key]) ~= "nil" then return self._proxy.writeable[key].Value end

  -- If its a child, return it.
  local c = self._proxy.children
  for i = 1, #c do
    if c[i].Name == key then
      return c[i]
    end
  end

  -- If none of the above, fail.
  error(string.format("%s is not a valid member of %s", key, self.ClassName), 2)
end

--- Create a table of property information given the input data.
-- @tparam string name The name of the property.
-- @tparam boolean readOnly Is this property only internally settable?
-- @param default The default value of something, or a function which returns a default value.
-- @tparam table allowedTypes The allowed types (either Instance or core lua type) this property can be.
-- @tparam table|nil onChange This function is run when a property is changed.
-- @note If default is a function, it will get passed a list of arguments -- namely, those passed to `Instance.New`
function Instance.Property(name, readOnly, default, allowedTypes, onChange)
  expect(1, name, "string")
  expect(2, readOnly, "boolean", "nil")

  return {
    name = name,
    readOnly = not not readOnly, -- convert to boolean if nil.
    default = default,
    onChange = onChange,
    allowedTypes = allowedTypes
  }
end

function Instance.GetInformation(className)
  return Instance.Classes[className]
end

local function MakeData(default, allowedTypes, ...)
  return {
    Value = type(default) == "function" and default(...) or default,
    AllowedTypes = allowedTypes
  }
end

function Instance.New(className, ...)
  local information = Instance.GetInformation(className)
  local obj = {
    _proxy = {
      readOnly = {
        Instance = MakeData(true, {"boolean"})
      },
      writeable = {
        Parent = MakeData(Instance.Nil, {"Instance", "nil"}),
        Archivable = MakeData(true, {"boolean"})
      },
      children = {},
      derives = {}
    }
  }

  for k, v in pairs(information.readOnly) do
    obj._proxy.readOnly[k] = MakeData(v.Default, v.AllowedTypes, ...)
  end
  for k, v in pairs(information.writeable) do
    obj._proxy.writeable[k] = MakeData(v.Default, v.AllowedTypes, ...)
  end
  for i = 1, #information.derives do
    obj._proxy.derives[i] = information.derives[i]
  end

  local function NewMethod(name)
    obj._proxy.readOnly[name] = MakeData(function() return func end, {"function"})
  end

  --- Remove absolutely everything.
  NewMethod("Destroy", function(self)
    expect(1, self, "table")
    if self.Parent ~= Instance.Nil then

    end
    for k, v in pairs(self._proxy.readOnly) do
      if v.Destroy then v:Destroy() end
      self._proxy.readOnly[k] = nil
    end
    for k, v in pairs(self._proxy.writeable) do
      if v.Destroy then v:Destroy() end
      self._proxy.writeable[k] = nil
    end
    self:ClearAllChildren()

    for k in pairs(self._proxy) do self._proxy[k] = nil end
    self._proxy = nil
  end)

  NewMethod("RemoveChild", function(self, name)
    expect(1, self, "table")
    expect(1, name, "string")
    local _, index = self:FindFirstChild(name)
    if index then
      table.remove(self._proxy.children, index)
    end
  end)

  -- remove all of the children.
  NewMethod("ClearAllChildren", function(self)
    expect(1, self, "table")

    local children = self._proxy.children
    for i = 1, #children do
      children[i]:Destroy()
      children[i] = nil
    end
  end)

  NewMethod("Clone", function(self)
    expect(1, self, "table")

    -- TODO: This.
  end)

  NewMethod("FindFirstAncestor", function(self, name)
    expect(1, self, "table")
    expect(2, name, "string")

    -- TODO: This.
  end)

  NewMethod("FindFirstAncestorOfClass", function(self, className)
    expect(1, self, "table")
    expect(1, className, "string")

    -- TODO: This.
  end)

  NewMethod("FindFirstAncestorWhichIsA", function(self, className)
    expect(1, self, "table")
    expect(1, className, "string")

    -- TODO: This.
  end)

  NewMethod("FindFirstChild", function(self, name, recursive)
    expect(1, self, "table")
    expect(1, name, "string")
    expect(1, recursive, "boolean", "nil")

    local c = self._proxy.children
    for i = 1, #c do
      if c[i].Name == name then
        return c[i], i
      end
    end
  end)

  NewMethod("FindFirstChildOfClass", function(self, className, recursive)
    expect(1, self, "table")
    expect(1, className, "string")
    expect(1, recursive, "boolean")

    -- TODO: This.
  end)

  NewMethod("FindFirstChildWhichIsA", function(self, className, recursive)
    expect(1, self, "table")
    expect(1, className, "string")
    expect(1, recursive, "boolean")

    -- TODO: This.
  end)

  NewMethod("FindFirstDescendant", function(self, name)
    expect(1, self, "table")
    expect(1, name, "string")

    -- TODO: This.
  end)

  NewMethod("GetActor", function(self)
    expect(1, self, "table")

    -- TODO: Figure out if I'm doing this.
  end)

  NewMethod("GetChildren", function(self)
    expect(1, self, "table")

    return TE.copy(self._proxy.children)
  end)

  NewMethod("GetDescendants", function(self)
    expect(1, self, "table")

    -- TODO: This.
  end)

  NewMethod("GetFullName", function(self)
    expect(1, self, "table")

    -- TODO: This.
  end)

  NewMethod("GetPropertyChangedSignal", function(self)
    expect(1, self, "table")

    -- TODO: Figure out if I'm doing signals.
  end)

  NewMethod("IsA", function(self, className)
    expect(1, self, "table")
    expect(1, className, "string")

    -- TODO: This.
  end)

  NewMethod("IsAncestorOf", function(self, descendant)
    expect(1, self, "table")
    expect(1, descendant, "table")

    -- TODO: This.
  end)

  NewMethod("WaitForChild", function(self, childName, timeOut)
    expect(1, self, "table")
    expect(1, childName, "string")
    expect(1, timeOut, "number", "nil")

    -- TODO: Figure out if I'm doing signals.
  end)

  return setmetatable(obj, instanceMT)
end

---
-- @tparam string className The name of the class to create.
-- @tparam table properties The property information for the class. Should be a list of `Instance.Property`s.
-- @tparam string|nil derives The class this object derives from. If that class has not been instantiated yet, this will throw an error.
function Instance.Create(className, properties, derives)
  expect(1, className, "string")
  expect(2, properties, "table")

  local obj = {
    readOnly = {
      ClassName = {Default = className, AllowedTypes = "string"}
    },
    writeable = {
      Name = ClassName
    },
    derives = {}
  }

  if derives then -- get the classes this class derives from.
    local info = Instance.GetInformation(derives)
    if info then
      for i, derivative in ipairs(info) do
        obj.derives[i] = derivative
      end

      obj.derives[#obj.derives + 1] = derives
    else
      error(string.format("Derivative class %d does not exist.", derives), 2)
    end
  end

  for i = 1, #properties do
    local property = properties[i]
    if property.readOnly then
      obj.readOnly[property.name] = {Default = property.default, OnChange = property.onChange, AllowedTypes = property.allowedTypes}
    else
      obj.writeable[property.name] = {Default = property.default, OnChange = property.onChange, AllowedTypes = property.allowedTypes}
    end
  end

  Instance.Classes[classname] = obj
end

function Instance.Finalize()
  Instance.Property = nil
  Instance.Create = nil
  Instance.Finalize = nil
end

return M
