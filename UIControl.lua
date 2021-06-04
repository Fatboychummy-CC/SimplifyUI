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

--[[ HELPER FUNCTIONS ]]
local function getPositionFromParent(uiObject, px, py)
  px = px or 0
  py = py or 0
  if uiObject == UIControl.NULL_UI then return px, py end
  if uiObject.Parent == UIControl.NULL_UI or not uiObject.Parent then -- if root object
    local tx, ty = term.getSize()
    return math.floor(uiObject.Position.X.Offset + uiObject.Position.X.Scale * tx - (uiObject.AnchorPoint.X.Offset + uiObject.AnchorPoint.X.Scale * uiObject.ActualSize.X.Offset) + 0.5),
           math.floor(uiObject.Position.Y.Offset + uiObject.Position.Y.Scale * ty - (uiObject.AnchorPoint.Y.Offset + uiObject.AnchorPoint.Y.Scale * uiObject.ActualSize.Y.Offset) + 0.5)
  else -- NOT root object.
    return math.floor(px + uiObject.Position.X.Offset + uiObject.Position.X.Scale * uiObject.Parent.ActualSize.X.Offset - (uiObject.AnchorPoint.X.Offset + uiObject.AnchorPoint.X.Scale * uiObject.ActualSize.X.Offset) + 0.5),
           math.floor(py + uiObject.Position.Y.Offset + uiObject.Position.Y.Scale * uiObject.Parent.ActualSize.Y.Offset - (uiObject.AnchorPoint.Y.Offset + uiObject.AnchorPoint.Y.Scale * uiObject.ActualSize.Y.Offset) + 0.5)
  end
end
local function getSizeFromParent(uiObject, px, py)
  px = px or 0
  py = py or 0
  if uiObject == UIControl.NULL_UI then return px, py end
  if uiObject.Parent == UIControl.NULL_UI or not uiObject.Parent then -- if root object
    local tx, ty = term.getSize()
    return math.floor(uiObject.Size.X.Offset + uiObject.Size.X.Scale * tx + 0.5),
           math.floor(uiObject.Size.Y.Offset + uiObject.Size.Y.Scale * ty + 0.5)
  else -- NOT root object.
    return math.floor(uiObject.Size.X.Offset + uiObject.Size.X.Scale * px + 0.5),
           math.floor(uiObject.Size.Y.Offset + uiObject.Size.Y.Scale * py + 0.5)
  end
end

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
      GetParents = function(self)
        local current = self
        local parentChain = {n = 1, self}
        while current and current.Parent do
          parentChain.n = parentChain.n + 1
          parentChain[parentChain.n] = current.Parent
          current = current.Parent
        end

        return parentChain
      end
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

  obj:SetPrePropertyChangedHandler(function(self, propertyName, newValue)
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

  obj:RegisterConnection("Position")
  obj:RegisterConnection("Size")
  obj:RegisterConnection("AnchorPoint")
  obj:RegisterConnection("Parent")

  obj:SetPostPropertyChangedHandler(function(self, propertyName, newValue)
    expect(1, self, "table")

    self:Update()
  end)

  local proxy = obj:GetProxy()
  proxy.Body = {W = 0, H = 0}
  proxy._isUIObject = true

  function proxy.readOnly.Update(self)
    if self.Parent and self.Parent ~= UIControl.NULL_UI then
      self.Parent:Update()
    end

    -- get parents
    local parentChain = self:GetParents()
    for k, v in pairs(parentChain) do print(k, v) end

    -- calculate actual size
    local sx, sy = 0, 0

    for i = parentChain.n, 1, -1 do
      sx, sy = getSizeFromParent(parentChain[i], sx, sy)
    end
    self.ActualSize.X.Offset = sx
    self.ActualSize.Y.Offset = sy

    -- calculate actual position
    local px, py = 0, 0 -- topmost parent should not have parent, so starting at 0, 0 is fine.

    for i = parentChain.n, 1, -1 do
      px, py = getPositionFromParent(parentChain[i], px, py)
    end
    self.ActualPosition.X.Offset = px
    self.ActualPosition.Y.Offset = py

    -- update children
    for i, child in List.Iterator(self.Children) do
      if UIControl.IsValid(child) then
        child:Update()
      end
    end
  end

  return obj
end)

return UIControl
