local UIControl = require "UIControl"
local expect = require "cc.expect"

local UIButton = {}

function UIButton.new(parentTerm, x, y, w, h, name, callback, parent)
  expect(1, parentTerm, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, w, "number")
  expect(5, h, "number")
  expect(6, name, "string")
  expect(7, callback, "function")
  expect(8, parent, "table", "nil")
  if parent and not UIControl.isValid(parent) then
    error("Cannot assign parent to non-UIObject.", 2)
  end

  local uiObject = UIControl.new(parentTerm, x, y, w, h, parent)

  -- add to the metatable.
  local mt = getmetatable(uiObject)

  function mt.__index.hit(self, x, y)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")

    return x >= self.x and x <= self.x + w - 1 and self.y >= self.y and self.y <= self.y + h - 1
  end

  return uiObject
end

return  UIButton
