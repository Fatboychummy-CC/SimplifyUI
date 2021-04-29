local UIControl = require "UIControl"
local expect = require "cc.expect".expect

local UIImage = {}

function UIImage.new(parentTerm, x, y, w, h, name, image, parent)
  expect(1, parentTerm, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, w, "number")
  expect(5, h, "number")
  expect(6, name, "string")
  expect(7, image, "table")
  expect(8, parent, "table", "nil")
  if parent and not UIControl.isValid(parent) then
    error("Cannot assign parent to non-UIObject.", 2)
  end

  local uiObject = UIControl.new(parentTerm, x, y, w, h, parent)

  -- copy the image to the body.
  local function changeImage(self, image)
    expect(1, self, "table")
    expect(2, image, "table")

    uiObject.body = image

    return self
  end

  changeImage(uiObject, image)

  -- add to the metatable.
  local mt = getmetatable(uiObject)

  mt.__index.changeImage = changeImage

  return uiObject
end

return UIImage
