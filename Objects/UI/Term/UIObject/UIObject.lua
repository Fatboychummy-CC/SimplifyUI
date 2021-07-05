--- UIObject
-- @module[kind=Instance] UIObject

local Instance = require "Objects.Instance"
local expect = require "cc.expect".expect


local UIObject = {
  ClassName = "UIObject",
  _creatable = false,
  _properties = {
    Visible = true,
    AnchorPoint = UDim2.new(0, 0, 0, 0),
    Position = UDim2.new(0, 0, 0, 0),
    AbsolutePosition = Vector2.new(0, 0),
    AutomaticSize = AutomaticSize.None,
    Size = UDim2.new(0, 0, 0, 0),
    AbsoluteSIze = Vector2.new(0, 0),
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
