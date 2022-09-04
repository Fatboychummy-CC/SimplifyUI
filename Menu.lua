---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

local Objects = require "SimplifyUI.Objects"
local Events = require "SimplifyUI.Events"

local Menu = {}

--- Create a new menu object.
---@diagnostic disable-next-line
---@param ... Window The window objects to be drawn to.
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

  ---Send the TICK event to all descendants.
  function Menu:TickDescendants()
    Menu:PushDescendants(Events.TICK)
  end

  Menu._DrawDescendants = Menu.DrawDescendants
  function Menu:DrawDescendants()
    Menu:PushDescendants(Events.PRE_DRAW)

    Menu:_DrawDescendants()
  end

  ---@param callback function? The function to be run in tandem with the menu.
  function Menu:Run(callback)

  end

  return menu
end

return Menu