--- UIControl is what every uiobject inherits from.
-- @author fatboychummy
-- @type UIText
-- @alias mt

local UIControl = require "UIControl"
local Enum = require "Objects.Enum"
local expect = require "cc.expect".expect

local UIText = {}

--- Text alignment enum.
-- @field TextAlign
-- @table TextFloat
-- @field Left
-- @field Centered
-- @field Right
UIText.TextAlign = Enum.New("Left", "Centered", "Right")

--- Text float enum.
-- @field TextFloat
-- @table TextFloat
-- @field Top
-- @field Centered
-- @field Bottom
UIText.TextFloat = Enum.New("Top", "Centered", "Bottom")

function UIText.new(parentTerm, x, y, w, h, name, text, fg, bg, parent)
  expect(1, parentTerm, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, w, "number")
  expect(5, h, "number")
  expect(6, name, "string")
  expect(7, text, "string")
  expect(8, fg, "string")
  expect(9, bg, "string")
  expect(10, parent, "table", "nil")
  if parent and not UIControl.isValid(parent) then
    error("Cannot assign parent to non-UIObject.", 2)
  end
  if #text ~= #fg or #fg ~= #bg then
    error("Bad arguments #6, 7, and 8 to UIText.new: Expected strings of equal length", 2)
  end

  local uiObject = UIControl.new(parentTerm, x, y, w, h, parent)

  -- copy the text to the body.
  local function changeText(self, text, fg, bg)
    expect(1, self, "table")
    expect(2, text, "string")
    expect(3, fg, "string")
    expect(4, bg, "string")

    if #text ~= #fg or #fg ~= #bg then
      error("Bad arguments #2, 3, and 4 to UIText.changeText: Expected strings of equal length", 2)
    end

    local converted = {{}}
    for i = 1, #text do
      local t, f, b = text:sub(i, i), fg:sub(i, i), bg:sub(i, i)
      converted[1][#converted[1] + 1] = {c = t, fg = f, bg = b, nt = true}
    end

    return self
  end


  -- add to the metatable.
  local mt = getmetatable(uiObject)

  mt.__index.changeText = changeText

  return uiObject
end

return UIText
