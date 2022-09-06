---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

---@enum Events
local Events = {
  -- System events
  PRE_DRAW = 1,
  TICK = 2,
  UPDATE_CLICKBOX = 3,

  -- Focus events
  FOCUS_CHANGE_CONTROL_YOURS = 4,
  FOCUS_CHANGE_CONTROL_STOP = 5,

  -- Mouse events
  MOUSE_DOWN = 6,
  MOUSE_UP = 7,
  MOUSE_CLICK = 8,
}

return Events