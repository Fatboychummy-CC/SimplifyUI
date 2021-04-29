--- UIControl is what every uiobject inherits from.
-- @author fatboychummy
-- @type UIControl

local expect = require "cc.expect".expect
local BasicClass = require "Objects.BasicClass"
local List = require "Objects.List"
local UDim, UDim2 = require "Objects.UDim", require "Objects.UDim2"

local UIControl = BasicClass.New(
  "UIControl",
  {
    IsValid = function(object)
      return type(t) == "table" and object.GetProxy and object:GetProxy()._isUIObject
    end
  },
  {},
  true
)

local UIControlProxy = UIControl:GetProxy()

UIControl:New(function(parentTerm, name, x, y, w, h, parent)
  expect(1, parentTerm, "table")
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
      Position = UDim2.FromOffset(x, y),
      Size = UDim2.FromOffset(w, h),
      AnchorPoint = UDim2.New(0, 0, 0, 0),

      -- temporary variables that will
      ActualPosition = UDim2.FromOffset(x, y),
      ActualSize = UDim2.FromOffset(w, h),
      Children = List.New(),
    },
    {
      Parent = nil,
      Name = name,
      ParentTerm = parentTerm
    }
  )

  local proxy = obj:GetProxy()
  proxy.Body = {W = 0, H = 0}
  proxy._isUIObject = true
end)
