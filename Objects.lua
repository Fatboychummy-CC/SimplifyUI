local expect = require "cc.expect".expect

local UDim, UDim2 = require "UDim", require "UDim2"

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

  obj.__Children = {}
  obj.__IsObject = true
  obj.__Type = object_type
  obj.Position = UDim2.new()

  function obj:GetChildren()
    return copy(self.__Children)
  end

  function obj:AddChild(child, switch)
    if child == self then
      error("Cannot add self to children.", 2)
    end

    if not self:FindChild(child) then
      table.insert(self.__Children, child)
    end
    
    if not switch then
      child.Parent = self
    end
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
        print("index:", idx)
        if idx == "Parent" then
          return self.__Parent
        elseif idx == "Children" then
          return self:GetChildren()
        end
      end,
      -- New index to protect the parent value and children value.
      __newindex = function(self, idx, new_val)
        print("New index:", idx, new_val)
        if idx == "Parent" then
          local _type = type(new_val)
          if _type ~= "table" and _type ~= "nil" then
            error("Cannot set parent to a non-table value (term object or object) or nil.", 2)
          end

          local parent = rawget(self, "__Parent")

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
          rawset(self, "__Parent", new_val)

          -- And check if the new parent is an object
          -- If not, it's likely just a term object.
          if _type == "table" and new_val.__IsObject then
            -- and add ourself to their list of children if so.
            new_val:AddChild(self, true)
          end
        elseif idx == "Children" then
          error("Do not set the children this way. Use Object:AddChild() or change Child.Parent instead.", 2)
        end

        return nil
      end
    }
  )
end

return Objects