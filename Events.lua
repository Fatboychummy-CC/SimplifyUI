local expect = require "cc.expect".expect

---@Enum Events
local Events = {
  PRE_DRAW = 1,
  TICK = 2,
  FOCUS_CHANGE_CONTROL_YOURS = 3,
  FOCUS_CHANGE_CONTROL_STOP = 4
}

return Events