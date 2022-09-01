local expect = require "cc.expect".expect

local Objects = {}

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

local function copy(t)
  local t_ = {}

  for k, v in pairs(t) do
    t_[k] = v
  end

  return t_
end

--- Create a new object type.
-- 
function Objects.new(property_dictionary, object_type)
  expect(1, property_dictionary, "table")
  expect(2, object_type, "string")

  local obj = dcopy(property_dictionary)

  obj.__Parent = term.current()
  obj.__Children = {}
  obj.__IsObject = true
  obj.__Type = object_type

  function obj:GetChildren()
    return copy(self.__Children)
  end

  function obj:AddChild(child)
    child.Parent = self
    table.insert(self.__Children, child)
  end

  function obj:FindChild(child)
    for i = 1, #self.__Children do
      if self.__Children[i] == child then
        return i
      end
    end
  end

  return setmetatable(obj, 
    {
      __tostring = function(self)
        return string.format("Object: %s", self.__Type)
      end,
      -- Index function to catch getting children and parent.
      __index = function(self, idx)
        if idx == "Parent" then
          return self.__Parent
        elseif idx == "Children" then
          return self:GetChildren()
        end
      end,
      -- New index to protect the parent value and children value.
      __newindex = function(self, idx, new_val)
        if idx == "Parent" then
          if type(new_val) ~= "table" then
            error("Cannot set parent to a non-table value (term object or object).", 2)
          end

          local parent = self.__Parent

          -- Check if there is already a parent
          if parent then
            if parent.__IsObject then
              -- Remove self from the parent's list of children
              local i = parent:FindChild(self)
              if i then
                table.remove(parent.__Children, i)
              end
            end
          end

          -- Then set our parent to the new parent
          self.__Parent = new_val

          -- And check if the new parent is an object
          -- If not, it's likely just a term object.
          if new_val.__IsObject then
            -- and add ourself to their list of children if so.
            new_val:AddChild(self)
          end
        elseif idx == "Children" then
          error("Do not set the children this way. Use Object:AddChild() or change Child.Parent instead.", 2)
        end
      end
    }
  )
end

return Objects