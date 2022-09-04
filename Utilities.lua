---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

local Utilities = {}

--- Linear interpolation between two values.
---@param a number The value to lerp from.
---@param b number The value to lerp to.
---@param alpha number The point between a and b (0-1)
---@return number interpolated The interpolated value.
function Utilities.Lerp(a, b, alpha)
  return a * (1-alpha) + b * alpha
end

--- Returns a function which can be used in parallel to run a specific coroutine
--- as needed. 
--- 
--- Please note that the focused thread should NEVER stop, instead when control
--- needs to change, it should be set to nil or the other thread.
---@return function Manager The coroutine manager.
---@return table Focus The sharable focus object, set Focus[1] to change the thread used.
function Utilities.FocusableCoroutine()
  local focus = {}

  return function()
    local coro ---@type thread?
    local waiting ---@type string?

    --- Resume a coroutine and set what filter we are waiting for
    local function resume(...)
      ---@diagnostic disable-next-line This is only called if coro is not nil.
      local ok, _waiting = coroutine.resume(coro, ...)
      waiting = _waiting

      -- If the coroutine stopped or errored...
      if not ok then
        if waiting == "cannot resume dead coroutine" then
          error("Focused coroutine stopped unexpectedly.", 0)
        end
        error(waiting, 0)
      end
    end

    -- Main loop: Pull event, check if we are changing focus, resume coroutine.
    while true do
      local event = table.pack(os.pullEvent())

      if event[1] == "coroutine_focus" then
        coro = focus[1]
        waiting = nil
        if coro then
          resume()
        end
      else
        if coro and (waiting == nil or waiting == event[1] or event[1] == "terminate") then
          resume(table.unpack(event, 1, event.n))
        end
      end

      if coro and coroutine.status(coro) == "dead" then
        error("Focused coroutine stopped unexpectedly.", 0)
      end
    end
  end, focus
end

--- Deep-clones a table.
---@param t table The table to be cloned.
---@return table clone A clone of the table inputted.
function Utilities.DCopy(t)
  local clone = {}

  for k, v in pairs(t) do
    if type(v) == "table" then
      clone[k] = Utilities.DCopy(v)
    else
      clone[k] = v
    end
  end

  return clone
end

--- Surface-clones a table.
---@param t table The table to be surface-cloned.
---@return table clone A surface-level clone of the table inputted.
function Utilities.Copy(t)
  local clone = {}

  for k, v in pairs(t) do
    clone[k] = v
  end

  return clone
end

return Utilities