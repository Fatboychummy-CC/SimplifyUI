--- Creates basic classes with integrations for events.
-- @author fatboychummy
-- @type BasicClass

local expect = require "cc.expect".expect
local Eventify = require "Objects.Eventify"
local lastID = 0

local function incLastID()
  lastID = lastID + 1
end

local coreLuaTypes = {
  "number",
  "string",
  "table",
  "function",
  "nil",
  "CFunction",
  "userdata"
}

local mod = {}

function mod.CheckType(object)
  local _type = type(object)

  if _type == "table" and type(object.ClassName) == "string" then
    return object.ClassName, true
  end

  for i = 1, #coreLuaTypes do
    if _type == coreLuaTypes[i] then
      return _type, false
    end
  end

  return "unknown", false
end

function mod.AssignmentError(name, type, types, offset, isClassType, isClassType2)
  error(
    string.format(
      "Cannot change field '%s' to item of %s %s. Expected %s %s.",
      name,
      isClassType and "class-type" or "type",
      type,
      isClassType2 and "class-type" or "type",
      table.concat(types, " or ")
    ),
    5 + offset
  )
end

function mod.ExpectOnChange(name, value, offset, ...)
  expect(1, name, "string")
  expect(3, offset, "number")
  local types = table.pack(...)

  for i = 1, types.n do
    expect(i + 3, types[i], "string")
    if type(value) == types[i] then
      return
    end
  end

  mod.AssignmentError(name, type(value), types, offset + 1, false, false)
end

function mod.ExpectItemOfClassOnChange(name, value, offset, ...)
  expect(1, name, "string")
  expect(3, offset, "number")
  local types = table.pack(...)
  for i = 1, types.n do
    if type(value) == "table" and value.ClassName == types[i] then
      return
    end
  end

  local _type, isClassType = "unknown", false
  if type(value) == "table" then
    if type(value.ClassName) == "string" then
      _type = value.ClassName
      isClassType = true
    else
      _type = "table"
    end
  else
    _type = type(value)
  end

  mod.AssignmentError(name, _type, types, offset + 1, isClassType, true)
end

--- Create a new class.
-- @tparam string classname The name of the class.
-- @tparam {[string] = any, ...} The read only properties.
-- @tparam {[string] = any, ...} The read-write properties.
-- @treturn BasicClass The created class.
function mod.New(classname, readOnlyProperties, writeableProperties, isConstructor)
  expect(1, classname, "string")
  expect(2, readOnlyProperties, "table", "nil")
  expect(3, writeableProperties, "table", "nil")

  incLastID()

  local obj = {} -- The object to be returned
  local proxy = { -- Proxy object that holds all the items.
    _classname = classname,
    _id = lastID,
    _prePropertyChangedHandler = function() return true, false, false end,
    _postPropertyChangedHandler = function() end,
    writeable = {},
    __newindex = function() end,
    __index = function() end
  }
  function proxy.tostring()
    return string.format("Class %s: ID %d", proxy._classname, proxy._id)
  end

  -- Events
  local formatString = string.format("%%s_%s%%d", proxy._classname)
  local function doFormatting(eventName)
    return string.format(formatString, eventName, proxy._id)
  end

  proxy.readOnly = {
    PropertyChangedEvent = Eventify(doFormatting("PropertyChanged")),
    RemovingEvent = Eventify(doFormatting("Removing")),
    ClassName = classname
  }

  -- Metatable of the object.
  local mt = {
    -- index metamethod: Check self first, then readOnly, then writeable.
    __index = function(self, k)
      if rawget(self, k) then return rawget(self, k) end
      if proxy.readOnly[k] then return proxy.readOnly[k] end
      if proxy.writeable[k] then return proxy.writeable[k] end
      if proxy.__index(k) then return proxy.__index(k) end
    end,
    -- tostring metamethod: Convert object to string.
    __tostring = function(self)
      return self:GetProxy().tostring()
    end,
    -- pairs metamethod: Return iterator to loop through self, then readOnly, then writeable
    __pairs = function(self)
      local toCheck = {self, proxy.readOnly, proxy.writeable}
      local selected = 1

      -- The actual iterator.
      local function iter(self, k)
        -- Select the next item.
        local v
        k, v = next(toCheck[selected], k)

        -- If the next item is nil, and we are not at the end
        if v == nil and selected < #toCheck then
          -- select the next inner table, then iterate through that.
          selected = selected + 1
          return iter(toCheck[selected], k)
        elseif v == nil then
          -- if next is nil, and we are at the end, exit.
          return nil
        end

        -- if first next was ok: Just return the value.
        return k, v
      end

      -- Return the iterator.
      return iter, self, nil
    end
  }
  -- newindex metamethod: Block writing to the readOnly portion.
  function mt.__newindex(self, k, v)
    local ok, types, isClassTypes
    local data = proxy._prePropertyChangedHandler(self, k, v)
    if not data.ok then
      local _type, isClassType = mod.CheckType(v)
      mod.AssignmentError(k, _type, data.expect, -2)
    end
    if data.ok and not data.handled then
      if not proxy.writeable[k] then
        if proxy.__newindex(k, v) then
          return
        end
        error(string.format("Cannot write to read-only (or non-existant) key '%s'.", k), 2)
      end

      proxy.writeable[k] = v
    end

    proxy._postPropertyChangedHandler(self, k, v)

    self.PropertyChangedEvent:Fire(self, k, v)
  end

  -- Copy methods and data to readonly and writeable portion.
  for k, v in pairs(readOnlyProperties) do
    proxy.readOnly[k] = v
  end
  for k, v in pairs(writeableProperties) do
    proxy.writeable[k] = v
  end

  if isConstructor then
    function obj:New(func)
      proxy.readOnly.New = function(...) incLastID() return func(...) end
      rawset(self, "New", nil)
    end
  end

  function obj:InjectNewIndex(f)
    expect(2, f, "function", "nil")
    rawset(self, "InjectNewIndex", nil)
    if not f then return end
    proxy.__newindex = f
  end

  function obj:InjectIndex(f)
    expect(2, f, "function", "nil")
    rawset(self, "InjectIndex", nil)
    if not f then return end
    proxy.__index = f
  end

  function obj:InjectMT(t)
    for k, v in pairs(t) do
      mt[k] = v
    end
    rawset(self, "InjectMT", nil)
  end

  function obj:SetPrePropertyChangedHandler(f)
    expect(2, f, "function")

    -- _prePropertyChangedHandler has same inputs as _postPropertyChangedHandler.
    -- _prePropertyChangedHandler expects the following return as a table:
    --[[
      {
        ok      = true/false,                 -- If the operation is ok to continue.
        expect  = {"typename", "classname"},  -- The expected lua types or class types (one or the other).
        handled = true/false                  -- If the operation was handled internally by the class (ie: don't perform the swap)
      }
    ]]
    proxy._prePropertyChangedHandler = f

    rawset(self, "SetPropertyChangedHandler", nil)
  end

  local connectionHandler = {}
  function obj:SetPostPropertyChangedHandler(f)
    expect(2, f, "function")
    proxy._postPropertyChangedHandler = function(obj, name, val)
      if connectionHandler[name] then
        connectionHandler[name]:Update()
      end
      return f(obj, name, val)
    end

    rawset(self, "SetPostPropertyChangedHandler", nil)
  end

  function obj:RegisterConnection(name, func)
    connectionHandler[name] = {}
    if obj[name].PropertyChangedEvent then
      connectionHandler[name].connection = obj[name].PropertyChangedEvent:Connect(function()
        obj.PropertyChangedEvent:Fire(obj, name, obj[name])
      end)
    end
    connectionHandler[name].Update = function(self)
      self.connection:Disconnect()
      if obj[name].PropertyChangedEvent then
        print("Updated handler for", name)
        print("New handler connection:", obj[name].PropertyChangedEvent.Name)
        self.connection = obj[name].PropertyChangedEvent:Connect(function()
          print("Connection called for", name)
          obj.PropertyChangedEvent:Fire(obj, name, obj[name])
        end)
      end
    end
  end

  --- Get the proxy table that contains all this object's data.
  -- @treturn table The proxy.
  function obj:GetProxy()
    return proxy
  end

  --- Remove this object, and any objects in the readOnly/writeable portion.
  function obj:Remove()
    self.RemovingEvent:Fire(self)
    for k, v in pairs(proxy.readOnly) do
      if type(v) == "table" and v.Remove then
        v:Remove()
      else
        proxy.readOnly[k] = nil
      end
    end
    for k, v in pairs(proxy.writeable) do
      if type(v) == "table" and v.Remove then
        v:Remove()
      else
        proxy.writeable[k] = nil
      end
    end

    setmetatable(self, nil)
  end

  return setmetatable(obj, mt), isConstructor and mt or nil
end

return mod
