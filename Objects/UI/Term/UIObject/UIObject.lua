--- UIObject
-- @module[kind=Instance] UIObject

local Instance = require "Objects.Instance"
local expect = require "cc.expect".expect

local function newUDim2()
  return Instance.new(UDim2, 0, 0, 0, 0)
end
local function newVector2()
  return Instance.new(Vector2, 0, 0)
end

local UIObject = {
  ClassName = "UIObject",
  _creatable = false,
  _properties = {
    Visible = true,
    AnchorPoint = newUDim2,
    Position = newUDim2,
    AbsolutePosition = newVector2,
    AutomaticSize = AutomaticSize.None,
    Size = newUDim2,
    AbsoluteSIze = newVector2,
    Selectable = false,
    Selected = false,
    Active = true,
    ClipsDescendants = false
  },
  SelectionColor = colors.cyan
  NULL_UI = {}
} --- @type UIObject
Instance.Register(UIObject)

UIObject._properties.NextSelectionUp = UIObject.NULL_UI
UIObject._properties.NextSelectionDown = UIObject.NULL_UI
UIObject._properties.NextSelectionRight = UIObject.NULL_UI
UIObject._properties.NextSelectionLeft = UIObject.NULL_UI

function UIObject:Draw()
  -- figure this out.
end

function UIObject:Update()
  -- figure this out.
end

function UIObject:TweenPosition(endPosition, easingDirection, easingStyle, time, override, callback)
  -- figure this out.
  local actor = self:GetActor()
end
function UIObject:TweenSize(endSize, easingDirection, easingStyle, time, override, callback)
  -- figure this out.
  local actor = self:GetActor()
end
function UIObject:TweenSizeAndPosition(endSize, endPosition, easingDirection, easingStyle, time, override, callback)
  -- figure this out.
  local actor = self:GetActor()
end

return UIObject
