local _require = require
local function _require(name)
  return require("SimplifyUI." .. name)
end

return {
  Objects = _require "Objects",
  UDim = _require "UDim",
  UDim2 = _require "UDim2",
  Buttons = _require "Buttons",
  Checkboxes = _require "Checkboxes",
  Lists = _require "Lists",
  Percentages = _require "Percentages",
  Scrollboxes = _require "Scrollboxes",
  Shapes = _require "Shapes",
  Sliders = _require "Sliders",
  Events = _require "Events",
  Utilities = _require "Utilities",
  Menu = _require "Menu"
}