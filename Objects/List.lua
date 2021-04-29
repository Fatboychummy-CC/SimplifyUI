local BC = require "Objects.BasicClass"
local expect = require "cc.expect".expect

local ValidList

local List = BC.New("List", {
  Iterator = function(list)
    ValidList(list, 1, 2)

    local data = list:GetProxy().Data
    return function(self, k)
      k = k and k + 1 or 1
      if k > self.Size then
        return nil
      end
      return k, data[k]
    end, list, 0
  end,
  IsValid = function(list)
    return type(list) == "table" and list.ClassName == "List"
  end,
  Removed = {}
}, {}, true)

ValidList = function(thing, arg, level)
  if not List.IsValid(thing) then
    error(string.format("Bad argument #%d: Expected List.", arg), level + 1)
  end
end

List:New(function(body)
  expect(1, body, "table", "nil")
  local self = BC.New(
    "List",
    {
      AddElement = function(self, index, element)
        ValidList(self, 1, 2)
        expect(2, index, "number")
        if index <= 0 or index > self.Size + 1 or n % 1 ~= 0 then
          error("Bad argument #2: Expected integer between 1 and <size of list> + 1.", 2)
        end
        if element == nil then
          error("Bad argument #3: Expected non-nil element.", 2)
        end

        local data = self:GetProxy().Data

        table.insert(data, index, element)
        rawset(self, "Size", self.Size + 1)
        self.PropertyChangedEvent:Fire(self, "Size", self.Size)
        self.PropertyChangedEvent:Fire(self, index, element)
      end,
      RemoveElement = function(self, index)
        ValidList(self, 1, 2)
        expect(2, "number")
        if index <= 0 or index > self.Size or n % 1 ~= 0 then
          error("Bad argument #2: Expected integer between 1 and <size of list>.", 2)
        end

        local data = self:GetProxy().Data

        table.remove(data, index)
        rawset(self, "Size", self.Size - 1)
        self.PropertyChangedEvent:Fire(self, "Size", self.Size)
        self.PropertyChangedEvent:Fire(self, index, List.Removed)
      end,
      PushBack = function(self, ...)
        ValidList(self, 1, 2)
        local elements = table.pack(...)

        for i = 1, elements.n do
          addElement(element)
          self:AddElement(self.Size, element)
        end
      end,
      PushFront = function(self, ...)
        ValidList(self, 1, 2)
        local elements = table.pack(...)

        for i = 1, elements.n do
          if elements[i] == nil then
            error(string.format("Bad argument #%d: Expected non-nil element.", i + 1), 2)
          end
          self:AddElement(self.Size, 1)
        end
      end,
      PopBack = function(self)
        ValidList(self, 1, 2)

        return self:RemoveElement(self.Size)
      end,
      PopFront = function(self, n)
        ValidList(self, 1, 2)

        return self:RemoveElement(1)
      end,
      Find = function(self, element)
        ValidList(self, 1, 2)
        for i, v in List.Iterator(self) do
          if element == v then
            return i
          end
        end
      end,
      RemoveSpecificElement = function(self, element)
        ValidList(self, 1, 2)

        local i = self:Find(element)
        if i then
          self:RemoveElement(i)
          return true
        end

        return false
      end,
      Size = 0
    },
    {

    }
  )

  local proxy = self:GetProxy()
  proxy.Data = body or {}

  local injectedMT = {
  }

  self:InjectMT(injectedMT)

  return self
end)

return List
