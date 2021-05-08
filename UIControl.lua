--- UIControl is what every uiobject inherits from.
-- @author fatboychummy
-- @type UIControl

local expect = require "cc.expect".expect
local BasicClass = require "Objects.BasicClass"
local List = require "Objects.List"
local UDim, UDim2 = require "Objects.UDim", require "Objects.UDim2"

local UIControl
UIControl = BasicClass.New(
  "UIControl",
  {
    IsValid = function(object)
      return (object == UIControl.NULL_UI) or (type(object) == "table" and object.GetProxy and object:GetProxy()._isUIObject)
    end,
    NULL_UI = {}
  },
  {},
  true
)

local UIControlProxy = UIControl:GetProxy()


local function isTermObject(v)
  local old = term.current()
  local ok = pcall(function()
    old = term.redirect(v)
    term.getTextColor()
  end)
  term.redirect(old)

  return ok
end

UIControl:New(function(parentTerm, name, x, y, w, h, parent)
  expect(1, parentTerm, "table")
  if not isTermObject(parentTerm) then
    error("Bad argument #1 to 'New': Expected Terminal Object, got " .. type(parentTerm) ..".", 1)
  end
  expect(2, name, "string")
  expect(3, x, "number", "nil")
  x = x or 0
  expect(4, y, "number", "nil")
  y = y or 0
  expect(5, w, "number", "nil")
  w = w or 0
  expect(6, h, "number", "nil")
  h = h or 0
  expect(7, parent, "table", "nil")
  if parent and not UIControl.IsValid(parent) then
    error("Cannot assign parent to non-UIObject.", 2)
  end

  local obj = BasicClass.New(
    "UIControl",
    {
      ActualPosition = UDim2.FromOffset(x, y),
      ActualSize = UDim2.FromOffset(w, h),
      Children = List.New(),
    },
    {
      Parent = UIControl.NULL_UI,
      Name = name,
      ParentTerm = parentTerm,
      Position = UDim2.FromOffset(x, y),
      Size = UDim2.FromOffset(w, h),
      AnchorPoint = UDim2.New(0, 0, 0, 0),
    }
  )

  obj:SetPropertyChangedHandler(function(self, propertyName, newValue)
    if propertyName == "Parent" then
      if UIControl.IsValid(newValue) then
        return true
      end
      return false, {"UIControl"}, true
    elseif propertyName == "Name" then
      if type(newValue) == "string" then
        return true
      end
      return false, {"string"}, false
    elseif propertyName == "ParentTerm" then
      if isTermObject(newValue) then
        return true
      end
      return false, {"Term"}, true
    elseif propertyName == "Position" or propertyName == "Size" or propertyName == "AnchorPoint" then
      if UDim2.IsValid(newValue) then
        return true
      end
      return false, {"UDim2"}, true
    end
    return true
  end)

  local proxy = obj:GetProxy()
  proxy.Body = {W = 0, H = 0}
  proxy._isUIObject = true

  return obj
end)

return UIControl
