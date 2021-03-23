local UIControl = require "UIControl"
local expect = require "cc.expect".expect

local UIWindow = {}

function UIWindow.new(parentTerm, x, y, w, h, name, parent)
  expect(1, parentTerm, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, w, "number")
  expect(5, h, "number")
  expect(6, name, "string")
  expect(7, parent, "table", "nil")
  if parent and not UIControl.isValid(parent) then
    error("Cannot assign parent to non-UIObject.", 2)
  end

  local uiObject = UIControl.new(parentTerm, x, y, w, h, name, parent)
  uiObject.classname = "UIWindow"

  local mt = getmetatable(uiObject)

  return uiObject
end

return UIWindow
