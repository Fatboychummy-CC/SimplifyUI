--- Instance
-- @module Instance


local InstanceRoot = {}
local Instance = {
  Archivable = false,
  ClassName = "Instance",
  Name = "Instance",
  Instances = {}
} --- @type Instance

--- Register a new instance type, for IsA.
-- @tparam string className The name of the class.
-- @tparam table|nil inherits The classes this class inherits from.
function Instance.Register(className, inherits)
  expect(1, className, "string")
  expect(2, inherits, "table", "nil")

  Instances[className] = inherits and inherits or {}
end

function Instance.CloneMetaTable()
  return {__index = Instance}
end

--- Create an instance.
-- @tparam table self The object to be created.
-- @treturn table the object created.
function Instance.new(class, ...)
  expect(1, class, "table")

  if not class.Construct then
    error(
      string.format(
        "Unable to create an Instance of type \"%s\"",
        class.ClassName and class.ClassName or "Unknown"
      )
    )
  end

  local AllInstances = {
    Archivable = true,
    ClassName = class.ClassName,
    Name = class.ClassName,
    Parent = InstanceRoot,
    Children = {}
  }

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

  return self._internal.Clone(self)
end

--- This function destroys all of an Instance’s children.
function Instance:ClearAllChildren()
  expect(1, self, "table")

  for i = 1, #self.Children do
    self.Children[i]:Destroy()
  end

  self.Children = {}
end


local function find(t, o)
  for i = 1, #t do
    if t[i] == o then return i end
  end
end

--- Sets the Instance.Parent property to nil, locks the Instance.Parent property, and calls Destroy on all children.
function Instance:Destroy()
  expect(1, self, "table")

  if self.Parent then
    local index = find(self.Parent.Children, self)
    table.remove(self.Parent.Children, index)
  end
  self.Parent = nil

  self:ClearAllChildren()

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
      self.Children[i]:FindFirstChild(name, true)
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
      self.Children[i]:FindFirstChildOfClass(className, true)
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
      self.Children[i]:FindFirstChildWhichIsA(className, true)
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
-- @treturn {Instance, ...} The Instance's children.
function Instance:GetChildren()
  expect(1, self, "table")

  return self.Children
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

  return table.concat(ancestry, '.')
end

--- Returns true if an Instance's class matches or inherits from a given class.
-- @tparam string className The name of the class to check for inheritance.
-- @treturn boolean If this object inherits from the given ClassName
function Instance:IsA(className)
  expect(1, self, "table")
  expect(2, className, "string")

  -- base case: this class is the class we're looking for.
  if self.ClassName == className then return true end

  -- else look at the inheritance list.
  local inheritance = Instance.Instances[self.ClassName]
  for i = 1, #inheritance do
    if className == inheritance[i] then
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
    if ancestor == self then return true end
    current = current.Parent
  end

  return false
end
