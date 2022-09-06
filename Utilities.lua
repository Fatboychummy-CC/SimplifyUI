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
---@return function manager The coroutine manager.
---@return table focus The sharable focus object, set Focus[1] to change the thread used.
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

--- Returns a function which can be used in parallel to run multiple coroutines
--- as needed. Two other functions are returned that allow you to add and remove
--- coroutines whenever needed.
---
---@return function manager The coroutine manager.
---@return fun(name:string, func:fun()|thread) coroutine_add The function that adds coroutines.
---@return fun(name:string) coroutine_remove The function that removes coroutines.
function Utilities.EditableCoroutine()
  local coroutines = {}
  local filters = {}

  --- Adds a coroutine to be run in the manager.
  ---@param name string The name of the coroutine.
  ---@param func fun()|thread The function to be converted to a coroutine, or a thread.
  local function coroutine_add(name, func)
    expect(1, name, "string")
    expect(2, func, "function", "thread")

    if type(func) == "function" then
      func = coroutine.create(func)
    end

    coroutines[name] = func
  end

  --- Removes a coroutine from the manager.
  ---@param name string The name of the coroutine to be removed.
  local function coroutine_remove(name)
    coroutines[name] = nil
    filters[name] = nil
  end

  --- Coroutine manager.
  local function manager()
    ---@param coro thread The coroutine to resume.
    ---@param name string The coroutine's name.
    ---@param ... any The values to resume with.
    local function resume(coro, name, ...)
      local ok, filter = coroutine.resume(coro, ...)
      
      -- If the coroutine stopped due to error, throw the error.
      if not ok then
        error(filter, 0)
      end

      filters[name] = filter
    end

    -- Main coroutine loop
    while true do
      -- Gather the event.
      local event = table.pack(os.pullEvent())

      -- Loop through each coroutine and check if it should be resumed.
      for name, coro in pairs(coroutines) do
        -- If filter is the same
        -- Or if filter is not set (take any event)
        -- Or if the event is a terminate event
        if event[1] == filters[name] or event[1] == "terminate" or not filters[name] then
          resume(coro, name, table.unpack(event, 1, event.n))

          -- If the coroutine finished, remove it.
          if coroutine.status(coro) == "dead" then
            coroutine_remove(name)
          end
        end
      end
    end
  end

  return manager, coroutine_add, coroutine_remove
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