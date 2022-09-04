---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

local Objects = require "SimplifyUI.Objects"
local Events = require "SimplifyUI.Events"

local Menu = {}
---@class Menu A menu object.
---@field ParentWindows table The parent windows this menu will draw to.
---@field TickRate number 

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
      Debug = false
    },
    "Menu"
  )
  ---@cast menu +Menu

  for i = 1, menu.ParentWindows.n do
    local win = menu.ParentWindows[i]
    ---@diagnostic disable-next-line
    menu.ParentWindows[i] = window.create(win, 1, 1, win.getSize())
  end

  ---Send the TICK event to all descendants.
  function menu:TickDescendants()
    self:PushDescendants(Events.TICK)
  end

  menu._DrawDescendants = menu.DrawDescendants
  function menu:DrawDescendants()
    self:PushDescendants(Events.PRE_DRAW)

    for i = 1, self.ParentWindows.n do
      self:_DrawDescendants()
    end
  end

  ---@param callback function? The function to be run in tandem with the menu.
  function menu:Run(callback)

  end

  return menu
end

return Menu