--- Instance
-- @module Instance

local expect = require "cc.expect".expect
local TE = require "Objects.Util.TableExtensions"

local Instance = {
  Archivable = false,
  ClassName = "Instance",
  Name = "Instance",
  Instances = {},
  INSTANCE_ROOT = {IsInstance = true}
} --- @type Instance


-- Children metatable for tracking ancestry.
local childrenMetaTable = {}
function childrenMetaTable:__len()
  return #self._proxy
end

function childrenMetaTable:__index(idx)
  return self._proxy[idx]
end

function childrenMetaTable:__newindex(idx, value)
  local proxy = self._proxy
  if type(idx) == "table" and idx.IsInstance then
    if value == nil then
      for i = 1, #proxy do
        if idx == proxy[i] then
          table.remove(proxy, i)
          return
        end
      end
    elseif value == true then
      table.insert(proxy, idx)
      return
    end
  end

  error("Do not insert manually to the children table, change the child Instance's 'Instance.Parent' instead.", 2)
end

--- Register a new instance type, for IsA.
-- @tparam Instance class The class to be registered.
-- @tparam {Instance, ...}|nil inherits The classes this class inherits from.
function Instance.Register(class, inherits)
  expect(1, class, "table")
  expect(2, inherits, "table", "nil")

  Instance.Instances[class] = inherits and inherits or {}
end

function Instance.DeRegister(class)
  expect(1, class, "table")

  Instance.Instances[class] = nil
end

function Instance.CloneMetaTable()
  return {
    __pairs = function()
      error("Invalid argument #1 to 'pairs' (table expected, got Instance)", 2)
    end,
    __index = function(self, idx) -- Index function, check if parent, else check instance table.
      -- Check if it's in this table.
      if self._proxy[idx] then
        return self._proxy[idx]
      end

      -- Check through Instance and return it.
      if Instance[idx] then return Instance[idx] end

      -- Check through the Instance's inheritance tree.
      local inheritance = Instance.Instances[self._proxy.Class]
      if inheritance then
        for i = 1, #inheritance do
          if inheritance[i][idx] then return inheritance[i][idx] end
        end
      end

      -- does not exist, error
      error(string.format("%s is not a valid member of %s \"%s\"", idx, self.ClassName, self:GetFullName()), 2)
    end,
    __newindex = function(self, idx, value)
      if self._WRITING then -- if we're still setting up the class-object...
        self._proxy[idx] = value -- forcefully write, don't generate events.
      else
        if idx == "Parent" then
          if type(value) ~= "table" and value ~= nil  then
            error(string.format("Invalid argument #3 (Instance or nil expected, got %s)", type(value)), 2)
          end
          if type(value) == "table" then
            if not value.IsInstance then
              error("Invalid argument #3 (Instance or nil expected, got table)", 2)
            end

            -- Tell the children metatable of the current parent to remove this value.
            if self._proxy.Parent ~= Instance.INSTANCE_ROOT then
              self._proxy.Parent.Children[value] = nil
            end

            -- set the new parent
            self._proxy.Parent = value

            -- tell the children metatable of the new parent to add this as a child.
            value.Children[self] = true
          else
            -- must be nil, tell parent to remove ourself from list of children
            if self._proxy.Parent.Children then
              self._proxy.Parent.Children[self] = nil
              self._proxy.Parent = Instance.INSTANCE_ROOT
            end
          end -- handle parent setting appropriately.
        elseif not self._proxy[idx] then
          error(string.format("%s is not a valid member of %s \"%s\"", idx, self.ClassName, self:GetFullName()), 2)
        end

        -- set the value
        self._proxy[idx] = value

        self:GetActor()("ScriptSignal", "PropertyChanged", idx, value)
      end
    end
  }
end


local function incomplete(field)
  return string.format("Attempt to create incomplete Instance (%s)", field)
end

local function getProperties(class)
  local properties = class._properties

  -- Allow initializer function for properties.
  if type(properties) == "function" then
    properties = properties()
  end

  -- Not a function,
  local clone = TE.deepCopy(properties) -- clone all the information from the class `_properties`
  local info = {}

  if type(clone) == "table" then
    for k, v in pairs(clone) do
      info[k] = type(v) == "function" and v() or v -- copy the data to our table.
    end
  end

  return info
end
--- Create an instance.
-- @tparam table self The object to be created. The most notable change from Roblox Instance to these Instances are that these Instance take the `require`d object instead of a string name.
-- @treturn table the object created.
function Instance.new(class, ...)
  expect(1, class, "table")

  if not Instance.Instances[class] then
    printError(class)
    printError(Instance.Instances[class])
    error(incomplete("Class registration incomplete"), 2)
  end
  if class == Instance then
    error("Unable to create Instance of Instance.", 2)
  end
  if not class._creatable then
    error("Attempt to create non-creatable class-type.", 2)
  end
  if not class.new then
    error(incomplete("Missing method: new"), 2)
  end
  if not class.ClassName then
    error(incomplete("Missing method: ClassName"), 2)
  end

  -- Register the data all instances should have.
  local AllInstances = {
    Children = setmetatable({_proxy = {}}, childrenMetaTable),
    _proxy = {
      Parent = Instance.INSTANCE_ROOT,
      Class = class,
      IsInstance = true,
      Archivable = true,
      ClassName = class.ClassName,
      Name = class.ClassName
    },
    _internal = {},
    _WRITING = true
  }

  AllInstances.Changed = ScriptSignal(AllInstances, "PropertyChanged")

  -- Register the properties from parent classes, if applicable.
  local parents = Instance.Instances[class]
  for i = 1, #parents do
    local current = parents[i]
    if current then
      local clone = getProperties(current)
      for k, v in pairs(clone) do
        AllInstances[k] = v -- copy all the properties to this object.
      end
    end
  end

  local clone = getProperties(class)
  for k, v in pairs(clone) do
    AllInstances[k] = v -- copy all the properties to this object.
  end

  return class.new(setmetatable(AllInstances, Instance:CloneMetaTable()), ...)
end

--- Clone an instance.
-- @tparam table self The object to be cloned.
-- @treturn table|nil if self.Archivable returns a clone of the object, otherwise returns nil.
function Instance:Clone()
  expect(1, self, "table")

  if not self.Archivable then return end

  if self == Instance then
    error("Cannot clone Instance.", 2)
  end

  if not self._internal.Clone then
    error(string.format("Unable to clone Instance \"%s\" due to missing method \"_internal.Clone\"", self.ClassName), 2)
  end

  return self._internal.Clone(self)
end

--- This function destroys all of an Instance’s children.
function Instance:ClearAllChildren()
  expect(1, self, "table")

  while self.Children[1] do
    self.Children[1]:Destroy()
  end
end


local function find(t, o)
  for i = 1, #t do
    if t[i] == o then return i end
  end
end

--- Sets the Instance.Parent property to nil, locks the Instance.Parent property, and calls Destroy on all children.
function Instance:Destroy()
  expect(1, self, "table")

  if not self._internal.Destroy then
    error(string.format("Destructor for Instance '%s' does not exist! It is of type '%s'.", self.Name, self.ClassName), 2)
  end

  self.Parent = nil

  self:ClearAllChildren()

  setmetatable(self, nil)

  self._internal.Destroy(self)
end

--- Returns the first ancestor of the Instance whose Instance.Name is equal to the given name.
-- @tparam string name The name of the ancestor to search for
-- @treturn Instance|nil If it found the ancestor, return it, else return nil.
function Instance:FindFirstAncestor(name)
  expect(1, self, "table")
  expect(2, name, "string")

  local current = self.Parent
  while type(current) == "table" do
    if current.Name == name then
      return current
    end
    current = current.Parent
  end

  return type(current) == "table" and current or nil
end

--- Returns the first ancestor of the Instance whose Instance.ClassName is equal to the given className.
-- @tparam string className The ClassName of the ancestor to search for.
-- @treturn Instance|nil If it found the ancestor, return it, else return nil.
function Instance:FindFirstAncestorOfClass(className)
  expect(1, self, "table")
  expect(2, className, "string")

  local current = self.Parent
  while type(current) == "table" do
    if current.ClassName == className then
      return current
    end
    current = current.Parent
  end

  return type(current) == "table" and current or nil
end

--- Returns the first ancestor of the Instance for whom Instance:IsA returns true for the given className
-- @tparam string className The ClassName of the ancestor to search for.
-- @treturn Instance|nil If it found the ancestor, return it, else return nil.
function Instance:FindFirstAncestorWhichIsA(className)
  expect(1, self, "table")
  expect(2, className, "string")

  local current = self.Parent
  while type(current) == "table" do
    if current:IsA(className) then
      return current
    end
    current = current.Parent
  end

  return type(current) == "table" and current or nil
end

--- Returns the first child of the Instance found with the given name.
-- @tparam string name The name of the child to search for.
-- @treturn Instance|nil If it found the child, return it, else return nil.
function Instance:FindFirstChild(name, recursive)
  expect(1, self, "table")
  expect(2, name, "string")
  expect(3, recursive, "boolean", "nil")

  for i = 1, #self.Children do
    if self.Children[i].Name == name then
      return self.Children[i]
    end
    if recursive then
      local child = self.Children[i]:FindFirstChild(name, true)
      if child then return child end
    end
  end
end

--- Returns the first child of the Instance whose ClassName is equal to the given className.
-- @tparam string className The ClassName of the child to search for.
-- @treturn Instance|nil If it found the child, return it, else return nil.
function Instance:FindFirstChildOfClass(className, recursive)
  expect(1, self, "table")
  expect(2, className, "string")
  expect(3, recursive, "boolean", "nil")

  for i = 1, #self.Children do
    if self.Children[i].ClassName == className then
      return self.Children[i]
    end
    if recursive then
      local child = self.Children[i]:FindFirstChildOfClass(className, true)
      if child then return child end
    end
  end
end

--- Returns the first child of the Instance for whom Instance:IsA returns true for the given className.
-- @tparam string name The name of the child to search for.
-- @treturn Instance|nil If it found the child, return it, else return nil.
function Instance:FindFirstChildWhichIsA(className, recursive)
  expect(1, self, "table")
  expect(2, className, "string")
  expect(3, recursive, "boolean", "nil")

  for i = 1, #self.Children do
    if self.Children[i]:IsA(className) then
      return self.Children[i]
    end
    if recursive then
      local child = self.Children[i]:FindFirstChildWhichIsA(className, true)
      if child then return child end
    end
  end
end

--- Returns the first descendant of the Instance whose Instance.Name is equal to name.
-- @tparam name The name of the descendant to find.
-- @treturn Instance|nil If it found the descendant, return it, else return nil.
function Instance:FindFirstDescendant(name)
  expect(1, self, "table")
  expect(2, name, "string")

  -- Check the direct children
  local found = self:FindFirstChild(name)
  if found then return found end

  -- check the children's children, in order.
  for i = 1, #self.Children do
    local found = self.Children[i]:FindFirstDescendant(name)
    if found then return found end
  end
end

--- Returns the Actor object this Instance is using.
-- @treturn Instance|nil If this object is using an Actor, return it, else return nil.
function Instance:GetActor()
  expect(1, self, "table")

  return self._internal.Actor
end

--- Returns an array containing all of the Instance's children.
-- @treturn {Instance, ...} A copy of the table of this Instance's children.
function Instance:GetChildren()
  expect(1, self, "table")

  local t = {}
  local proxy = self.Children._proxy

  for i = 1, #proxy do
    t[i] = proxy[i]
  end

  return t
end

--- Returns a string describing the Instance's ancestry.
-- @treturn string The Instance's ancestry.
function Instance:GetFullName()
  expect(1, self, "table")

  local ancestry = {self.Name}

  local current = self.Parent
  while type(current) == "table" do
    table.insert(ancestry, 1, current.Name)
    current = current.Parent
  end

  table.insert(ancestry, 1, "term")

  return table.concat(ancestry, '.')
end

--- Returns true if an Instance's class matches or inherits from a given class.
-- @tparam string className The name of the class to check for inheritance.
-- @treturn boolean If this object inherits from the given ClassName
function Instance:IsA(className)
  expect(2, className, "string")

  -- Base case: if not a table, or not an instance, return false.
  if type(self) ~= "table" then return false end
  if not self.IsInstance then return false end

  -- base case: this class is the class we're looking for.
  if self.ClassName == className then return true end

  -- else look at the inheritance list.
  local inheritance = Instance.Instances[self._proxy.Class]
  for i = 1, #inheritance do
    if className == inheritance[i].ClassName then
      return true
    end
  end

  return false
end

--- Returns true if an Instance is an ancestor of the given descendant.
-- @tparam Instance descendant Instance to check.
-- @treturn boolean If this Instance is an ancestor of the descendant.
function Instance:IsAncestorOf(descendant)
  expect(1, self, "table")
  expect(2, descendant, "table")

  for i = 1, #self.Children do
    -- if it's a direct child
    if self.Children[i] == descendant then
      return true
    end

    -- if its a child of the child of the child ..................
    if self.Children[i]:IsAncestorOf(descendant) then
      return true
    end
  end

  return false
end

--- Returns true if an Instance is a descendant of the given ancestor.
-- @tparam Instance ancestor The Instance to check.
-- @treturn boolean If this Instance is a descendant of the ancestor.
function Instance:IsDescendantOf(ancestor)
  expect(1, self, "table")
  expect(2, ancestor, "table")

  local current = self.Parent
  while type(current) == "table" do
    if current == ancestor then return true end
    current = current.Parent
  end

  return false
end

function Instance:GetDebugID()
  expect(1, self, "table")

  return self:GetActor().actorID
end

return Instance
