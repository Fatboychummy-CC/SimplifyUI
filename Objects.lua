---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

local UDim2 = require "SimplifyUI.UDim2"

local Objects = {}
---@class Object
---@field Position UDim2 The position of this object.
---@field _Position {[1]:number,[2]:number} The absolute position of this object, updated when drawing.
---@field Size UDim2 The size of this object.
---@field _Size {[1]:number,[2]:number} The absolute size of this object, updated when drawing.
---@field ClickBox {number:{number:boolean}} Positions in which clicking will click this object.
---@field DrawOrder number The order this object will be drawn in. Lower values prioritized.
---@field Enabled boolean Whether this object is enabled or not (able to receive events, and is drawn)
---@field Events {string:{number:function}} The events this object has subscriptions to.
---@field Children {number:Object} Equivalent to Object:GetChildren().
---@field Left Object? The object marked as "to the left" of this object.
---@field Right Object? The object marked as "to the right" of this object.
---@field Down Object? The object marked as "below" this object.
---@field Up Object? The object marked as "above" this object.
---@field _Children {number:Object}
---
---@field GetChildren function Get the children of this object.
---@field GetDescendants function Get all descendants of this object.
---@field AddChild function Add a child to this object.
---@field FindChild function Find a specific child in this object.
---@field Redraw function Replicate a redraw call up to parent, then have the parent redraw all descendants.
---@field DrawDescendants function Draw all descendants of this object.
---@field Push function Push an event to this object.
---@field PushDescendants function Push an event to all descendants of this object.

---@param t table The table to be deep-cloned.
local function dcopy(t)
  local t_ = {}
  
  for k, v in pairs(t) do
    if type(v) == "table" then
      t_[k] = dcopy(v)
    else
      t_[k] = v
    end
  end

  return t_
end

---@param t table The table to be surface-cloned.
local function copy(t)
  local t_ = {}

  for k, v in pairs(t) do
    t_[k] = v
  end

  return t_
end

--- Create a new object type.
---@param property_dictionary {string:any} The properties to initialize the object with.
---@param object_type string The name of the object's class.
---@return Object obj The object initialized.
---@nodiscard
function Objects.new(property_dictionary, object_type)
  expect(1, property_dictionary, "table")
  expect(2, object_type, "string")

  local obj = dcopy(property_dictionary) ---@cast obj Object

  obj._Children = {}
  obj._IsObject = true
  obj._Type = object_type
  obj.Position = UDim2.new()
  obj.Size = UDim2.new()
  obj._Position = {0, 0}
  obj._Size = {0, 0}
  obj.ClickBox = {}
  obj.DrawOrder = 0
  obj.Enabled = true
  obj.Events = {} -- [[ {eventname = {id=listener, id=listener, ...}} ]]

  function obj:GetChildren()
    return copy(self._Children)
  end

  function obj:GetDescendants()
    local descendants = {}
    
    -- for each child
    for _, child in ipairs(self._Children) do
      -- insert the child
      table.insert(descendants, child)

      -- then get the child's descendants.
      local descendants = child:GetDescendants()

      -- and add them to the list.
      for _, descendant in ipairs(descendants) do
        table.insert(descendants, descendant)
      end
    end

    return descendants
  end

  ---@param child Object The child object to be added.
  ---@param switch boolean|nil If true, will set the child's parent as well.
  function obj:AddChild(child, switch)
    if child == self then
      error("Cannot add self to children.", 2)
    end

    -- ensure we aren't already a child.
    if not self:FindChild(child) then
      table.insert(self._Children, child)
    end
    
    -- use the child's parent metavalue to update its parent.
    if not switch then
      child.Parent = self
    end
  end

  ---@param child Object The child object to search for.
  function obj:FindChild(child)
    for i = 1, #self._Children do
      if self._Children[i] == child then
        return i
      end
    end
  end

  function obj:Redraw()
    if self._Parent then
      self._Parent:Redraw()
    else
      self:Draw()
      self:DrawDescendants()
    end
  end

  function obj:DrawDescendants()
    local children = self._Children
    
    table.sort(children, function(a, b) return a.DrawOrder < b.DrawOrder end)
    for i = 1, #children do
      children[i]:Draw()
      children[i]:DrawChildren()
    end
  end

  ---@param event Events The event to subscribe to.
  ---@param name string The name of the connection. This is used for removing a listener.
  ---@param listener function The function called when the event is pushed.
  function obj:AddListener(event, name, listener)
    if not self.Events[event] then
      self.Events[event] = {}
    end

    self.Events[event][name] = listener
  end

  ---@param event Events The event to unsubscribe from.
  ---@param name string The name of the connection to remove.
  function obj:RemoveListener(event, name)
    if self.Events[event] then
      self.Events[event][name] = nil
    end
  end

  ---@param event string The event to be sent.
  ---@param ... any The event arguments.
  function obj:Push(event, ...)
    if self.Events[event] then
      for k, v in pairs(self.Events[event]) do
        v(...)
      end
    end
  end

  ---@param event string The event to be sent.
  ---@param ... any The event arguments.
  function obj:PushChildren(event, ...)
    local children = self._Children

    for i = 1, #children do
      children[i]:Push(event, ...)
      children[i]:PushChildren(event, ...)
    end
  end

  return setmetatable(obj, 
    {
      __tostring = function(self)
        return string.format("Object: %s", self._Type)
      end,
      -- Index function to catch getting children and parent.
      __index = function(self, idx)
        if idx == "Parent" then
          return self._Parent
        elseif idx == "Children" then
          return self:GetChildren()
        end
      end,
      -- New index to protect the parent value and children value.
      __newindex = function(self, idx, new_val)
        if idx == "Parent" then
          local _type = type(new_val)
          if _type ~= "table" and _type ~= "nil" then
            error("Cannot set parent to a non-table value (term object or object) or nil.", 2)
          end

          local parent = rawget(self, "_Parent")

          -- Check if there is already a parent
          if parent then
            if parent._IsObject then
              -- Remove self from the parent's list of children
              local i = parent:FindChild(self)
              if i then
                table.remove(parent._Children, i)
              end
            end
          end

          -- Then set our parent to the new parent
          rawset(self, "_Parent", new_val)

          -- And check if the new parent is an object
          -- If not, it's likely just a term object.
          if _type == "table" and new_val._IsObject then
            -- and add ourself to their list of children if so.
            new_val:AddChild(self, true)
          end

          return
        elseif idx == "Children" then
          error("Do not set the children this way. Use Object:AddChild() or change Child.Parent instead.", 2)
        end

        rawset(self, idx, new_val)
      end
    }
  )
end

return Objects