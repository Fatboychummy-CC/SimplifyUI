---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

---@enum Events
local Events = {
  -- System events
  PRE_DRAW = 1,
  TICK = 2,

  -- Focus events
  FOCUS_CHANGE_CONTROL_YOURS = 3,
  FOCUS_CHANGE_CONTROL_STOP = 4,

  -- Mouse events
  MOUSE_DOWN = 5,
  MOUSE_UP = 6,
  MOUSE_CLICK = 7
}

return Events