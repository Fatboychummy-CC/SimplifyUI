---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

local Objects = require "SimplifyUI.Objects"
local Events = require "SimplifyUI.Events"
local Utilities = require "SimplifyUI.Utilities"

local Menu = {}
---@class Menu A menu object.
---@field ParentWindows table The parent windows this menu will draw to.
---@field TickRate number The rate at which the Tick event is sent to descendants. This is only calculated once at startup.
---@field DrawSpeed number The rate at which the screen is redrawn. This is only calculated once at startup.
---@field Debug boolean If true, creates a window and displays useful information.
---@field Focused Object? The currently focused object. This should not be set manually.
---@field ArrowsFocus boolean Whether the arrow keys should change focus.

--- Create a new menu object.
---@diagnostic disable-next-line
---@param ... Window The window objects to be drawn to.
---@return Menu|Object
---@nodiscard
function Menu.new(...)
  local menu = Objects.new(
    {
      ParentWindows = table.pack(...),
      TickRate = 10,
      Debug = false,
      ArrowsFocus = true
    },
    "Menu"
  )
  ---@cast menu +Menu

  for i = 1, menu.ParentWindows.n do
    local win = menu.ParentWindows[i]
    ---@diagnostic disable-next-line
    menu.ParentWindows[i] = window.create(win, 1, 1, win.getSize())
  end

  --- Send the TICK event to all descendants.
  function menu:TickDescendants()
    self:PushDescendants(Events.TICK)
  end

  --- Draw all descendants.
  menu._DrawDescendants = menu.DrawDescendants
  function menu:DrawDescendants()
    self:PushDescendants(Events.PRE_DRAW)

    for i = 1, self.ParentWindows.n do
      self:_DrawDescendants()
    end
  end

  ---@param object Object The object to set the focus to.
  function menu:SetFocus(object)
    self.Focused:Push(Events.FOCUS_CHANGE_CONTROL_STOP)
    self.Focused = object
    self.Focused:Push(Events.FOCUS_CHANGE_CONTROL_YOURS)
    os.queueEvent("focus_change")
  end

  ---@param callback function? The function to be run in tandem with the menu.
  function menu:Run(callback)
    -- This needs to do the following:
    -- 1. Run callback (of course)
    -- 2. Redraw at specific speed
    -- 3. Tick at specific speed
    -- 4. Determine focus, handle keyboard events (arrows and whatnot)
    -- 5. On focus change, send FOCUS_CHANGE_CONTROL_YOURS and
    --    FOCUS_CHANGE_CONTROL_STOP

    local tick_speed = 1 / self.TickRate
    local draw_speed = 1 / self.DrawSpeed

    local focus_manager, focus = Utilities.FocusableCoroutine()
    
    parallel.waitForAny(
      function() -- Focused coroutine manager
        while true do
          if not self.Focused and not self.Focused._OnFocus then
            focus[1] = nil
            os.queueEvent("coroutine_focus")
            os.pullEvent("focus_change")
          end

          focus[1] = self.Focused._OnFocus
          os.queueEvent("coroutine_focus")
          os.pullEvent("focus_change")
        end
      end,
      focus_manager,
      function() -- Control
        -- Start the timers
        local tick_timer = os.startTimer(tick_speed)
        local draw_timer = os.startTimer(draw_speed)

        while true do
          local event = table.pack(os.pullEvent())

          if event[1] == "timer" then
            -- Check if one of our timers expired.
            if event[2] == tick_timer then
              self:TickDescendants()
              tick_timer = os.startTimer(tick_speed)
            elseif event[2] == draw_timer then
              self:DrawDescendants()
              draw_timer = os.startTimer(draw_speed)
            end
          elseif event[1] == "key" and self.ArrowsFocus then
            -- If arrows change focus, check for those
            if self.Focused then -- if focused
              local key = event[1]
              local selection ---@type Object

              -- determine which object we would be changing focus to.
              if key == keys.right then
                selection = self.Focused.Right
              elseif key == keys.up then
                selection = self.Focused.Up
              elseif key == keys.left then
                selection = self.Focused.Left
              elseif key == keys.down then
                selection = self.Focused.Down
              end

              -- if we can move in that direction, change the focus.
              if selection then
                self:SetFocus(selection)
              end
            end
          end
        end
      end,
      callback -- user-given callback
    )
  end

  return menu
end

return Menu