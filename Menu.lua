---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

local Objects = require "SimplifyUI.Objects"
local Events = require "SimplifyUI.Events"
local Utilities = require "SimplifyUI.Utilities"
local WindowSources = require "SimplifyUI.WindowSources"

---@class Window

---@class Term

---@class WindowSource 
---@field Source WindowSources The source of the window.
---@field Window Window The window created for this wrapped window.
---@field Offset {[1]:integer,[2]:integer} The offset of this window on the terminal.
---@field Name string? The name of the monitor this window is on.

local Menu = {}
---@class Menu A menu object.
---@field ParentWindows {number:Window} The parent windows this menu will draw to.
---@field TickRate number The rate at which the Tick event is sent to descendants. This is only calculated once at startup.
---@field DrawSpeed number The rate at which the screen is redrawn. This is only calculated once at startup.
---@field Debug boolean If true, creates a window and displays useful information.
---@field Focused Object? The currently focused object. This should not be set manually.
---@field ArrowsFocus boolean Whether the arrow keys should change focus.
---@field AllowFocusChange boolean Whether or not the focus can change.
---@field ClickBox {number:{number:Object}} The map of what object corresponds to what position when clicked.
---@field _Manager fun() A coroutine manager that can add and remove items as needed.
---@field _Add fun(name:string, func:fun()|thread) Adds a thread to the coroutine manager.
---@field _Remove fun(name:string) Removes as thread from the coroutine manager.

---@param win Term The term object to be wrapped (term, window, monitor).
---@param source WindowSources The source window type to be used.
---@param a integer|string? The X offset (windows) or name of monitor.
---@param b integer? The Y offset.
---@param c string? The name of the monitor (monitor window)
---@overload fun(win:Term, source:WindowSources|1) For direct use on a terminal.
---@overload fun(win:Term, source:WindowSources|2, a:integer, b:integer) For use on a window on a terminal.
---@overload fun(win:Term, source:WindowSources|3, a:integer, b:integer, c:string) For use on a window on a monitor.
---@overload fun(win:Term, source:WindowSources|4, a:string) For use on a monitor.
---@return WindowSource wrapped The wrapped window source.
function Menu.WrapWindow(win, source, a, b, c)
  expect(1, win, "table")
  expect(2, source, "number")

  if source == WindowSources.TERMINAL then
    return {
      Source = WindowSources.TERMINAL,
      Window = window.create(win, 1, 1, win.getSize()),
      Offset = {0, 0}
    }
  elseif source == WindowSources.TERMINAL_WINDOW then
    expect(3, a, "number")
    expect(4, b, "number")

    return {
      Source = WindowSources.TERMINAL_WINDOW,
      Window = window.create(win, 1, 1, win.getSize()),
      Offset = {a, b}
    }
  elseif source == WindowSources.MONITOR_WINDOW then
    expect(3, a, "number")
    expect(4, b, "number")
    expect(5, c, "string")

    return {
      Source = WindowSources.MONITOR_WINDOW,
      Window = window.create(win, 1, 1, win.getSize()),
      Offset = {a, b},
      Name = c
    }
  elseif source == WindowSources.MONITOR then
    expect(3, a, "string")

    return {
      Source = WindowSources.MONITOR,
      Window = window.create(win, 1, 1, win.getSize()),
      Offset = {0, 0},
      Name = a
    }
  end

  error(string.format("Unknown window source: %d", source), 2)
end

--- Create a new menu object.
---@param ... WindowSource The window objects to be drawn to.
---@return Menu|Object
---@nodiscard
function Menu.new(...)
  local menu = Objects.new(
    {
      ParentWindows = table.pack(...),
      TickRate = 10,
      Debug = false,
      ArrowsFocus = true,
      AllowFocusChange = true,
      Offset = {0, 0},
    },
    "Menu"
  )
  ---@cast menu +Menu
  local manager, add, remove = Utilities.EditableCoroutine()
  menu._Manager = manager
  menu._Add = add
  menu._Remove = remove

  for i = 1, menu.ParentWindows.n do
    local win = menu.ParentWindows[i]
    if not win.Window or not win.Source or not win.Source then
      error(string.format("Invalid wrapped window #%d.", i), 2)
    end
    win.Window.setVisible(false)
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

  ---@param object Object? The object to set the focus to.
  ---@return boolean focus_changed Whether or not the focus was able to be changed.
  function menu:SetFocus(object)
    if self.AllowFocusChange then
      self.Focused:Push(Events.FOCUS_CHANGE_CONTROL_STOP)
      self.Focused = object
      self.Focused:Push(Events.FOCUS_CHANGE_CONTROL_YOURS)
      os.queueEvent("focus_change")
      return true
    end

    return false
  end

  ---@todo This
  function menu:Register(obj)

  end

  ---@param callback fun()? The function to be run in tandem with the menu.
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
      self._Manager,
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

              -- if changed then
              for _, win in ipairs(self.ParentWindows) do
                win.setVisible(true)
                win.setVisible(false)
              end
              -- end

              draw_timer = os.startTimer(draw_speed)
            end
          elseif event[1] == "key" and self.ArrowsFocus and self.AllowFocusChange then
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
          elseif event[1] == "mouse_click" then
            
          end
        end
      end,
      callback -- user-given callback
    )
  end

  return menu
end

return Menu