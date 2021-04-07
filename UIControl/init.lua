--- UIControl is what every uiobject inherits from.
-- @author fatboychummy
-- @type UIControl
-- @alias mt


local UIControl = {}
local expect = require "cc.expect".expect
local UDim, UDim2 = require "Objects.UDim", require "Objects.UDim2"

--- Small check to determine if this is a valid UI object.
-- @treturn bool If the object is a UI object or not.
function UIControl.IsValid(t)
  return type(t) == "table" and t._isUIObject
end

--- Create a new UIControl object.
-- @tparam parentTerm {table} The parent terminal this object should be drawn to.
-- @tparam name {string} The name of this object.
-- @tparam x {number, nil} The x offset of this object (Default 0).
-- @tparam y {number, nil} The y offset of this object (Default 0).
-- @tparam w {number, nil} The width offset of this object (Default 0).
-- @tparam h {number, nil} The height offset of this object (Default 0).
-- @tparam parent {UIControl, nil} The UI object this object is a child of (Default nil).
-- @treturn {UIControl} The UIControl object created.
function UIControl.new(parentTerm, name, x, y, w, h, parent)
  expect(1, parentTerm, "table")
  expect(2, name, "string")
  expect(3, x, "number", "nil")
  expect(4, y, "number", "nil")
  expect(5, w, "number", "nil")
  expect(6, h, "number", "nil")
  expect(7, parent, "table", "nil")
  if parent and not UIControl.IsValid(parent) then
    error("Cannot assign parent to non-UIObject.", 2)
  end

  local mt = {__index = {
    _classname = "UIControl",
    _isUIObject = true,
  }}
  local deepmt = {__index = {}}

  local function restrictedTable(t)
    return setmetatable(t or {}, deepmt)
  end

  -- @table uiObject
  -- @within UIControl
  -- @field Position The base position of this object before drawing.
  -- @field Size The base size of this object before drawing.
  -- @field AnchorPoint The location on this object that acts as the "centerpoint" of the object.
  -- @field ActualPosition The actual position of this object when drawing.
  -- @field ActualSize The actual size of this object when drawing.
  -- @field Name The name of this object.
  -- @field Body The drawn part of the object.
  -- @field Parent The parent of this object, if any.
  -- @field ParentTerm The parent terminal object this object will be drawn to.
  -- @field Children A list of all children this ui object contains.
  local uiObject = setmetatable({
    -- positioning
    Position = UDim2.FromOffset(x or 0, y or 0),
    Size = UDim2.FromOffset(w or 0, h or 0),
    AnchorPoint = UDim2.New(0, 0, 0, 0),

    -- "local" positioning: Position the object will actually be drawn at
    -- determined in _update function.
    ActualPosition = restrictedTable{X = x or 0, Y = y or 0},
    ActualSize = restrictedTable{W = w or 0, H = h or 0},

    -- object information
    Name = name,
    Body = restrictedTable{W = 0, H = 0},
    Parent = parent,
    ParentTerm = parentTerm,
    Children = restrictedTable{},
  }, mt)

  local function blockNewIndex()
    error("Assigning manually is restricted. Use setter methods instead.", 2)
  end

  deepmt.__newindex = blockNewIndex

  -- Determines the 'local' position of this object.
  -- Crawl backwards through list of parents.
  -- Get location this object should be drawn at.
  --
  local function getPositionFromParent(uiObject, px, py)
    px = px or 0
    py = py or 0
    if not uiObject.Parent then -- if root object
      local tx, ty = term.getSize()
      return math.floor(uiObject.Position.X.Offset + uiObject.Position.X.Scale * tx - (uiObject.AnchorPoint.X.Offset + uiObject.AnchorPoint.X.Scale * uiObject.ActualSize.W) + 0.5),
             math.floor(uiObject.Position.Y.Offset + uiObject.Position.Y.Scale * ty - (uiObject.AnchorPoint.Y.Offset + uiObject.AnchorPoint.Y.Scale * uiObject.ActualSize.H) + 0.5)
    else -- NOT root object.
      return math.floor(px + uiObject.Position.X.Offset + uiObject.Position.X.Scale * px - (uiObject.AnchorPoint.X.Offset + uiObject.AnchorPoint.X.Scale * uiObject.ActualSize.W) + 0.5),
             math.floor(py + uiObject.Position.Y.Offset + uiObject.Position.Y.Scale * py - (uiObject.AnchorPoint.Y.Offset + uiObject.AnchorPoint.Y.Scale * uiObject.ActualSize.H) + 0.5)
    end
  end
  local function getSizeFromParent(uiObject, px, py)
    px = px or 0
    py = py or 0
    if not uiObject.Parent then -- if root object
      local tx, ty = term.getSize()
      return math.floor(uiObject.Size.X.Offset + uiObject.Size.X.Scale * tx + 0.5),
             math.floor(uiObject.Size.Y.Offset + uiObject.Size.Y.Scale * ty + 0.5)
    else -- NOT root object.
      return math.floor(uiObject.Size.X.Offset + uiObject.Size.X.Scale * px + 0.5),
             math.floor(uiObject.Size.Y.Offset + uiObject.Size.Y.Scale * py + 0.5)
    end
  end

  --- Update the UIControl object.
  -- Iterates through all the things that need to change, (position, size, etc) whenever specific events occur.
  function mt.__index._update(self)
    local x, y = self:GetActualPosition()
    local w, h = self:GetActualSize()
    rawset(self.ActualPosition, "X", x)
    rawset(self.ActualPosition, "Y", y)
    rawset(self.ActualSize, "W", w)
    rawset(self.ActualSize, "H", h)
  end

  --- Reposition this UI object.
  -- It is recommended to use this rather than manually setting the position, as this method updates the UI object after the change.
  -- @tparam {UDim2} udim2 The UDim2 used to replace the position.
  -- @treturn {UIControl} self
  function mt.__index.Reposition(self, udim2)
    expect(1, self, "table")
    expect(2, udim2, "table")
    if not UDim2.IsValid(udim2) then
      error("Invalid argument #2: Expected UDim2.", 2)
    end

    rawset(self, "Position", udim2)
    self:_update()

    return self
  end

  --- Resize this UI object.
  -- It is recommended to use this rather than manually setting the size, as this method updates the UI object after the change.
  -- @tparam {UDim2} udim2 The UDim2 used to replace the size.
  -- @treturn {UIControl} self
  function mt.__index.Resize(self, udim2)
    expect(1, self, "table")
    expect(2, udim2, "table")
    if not UDim2.IsValid(udim2) then
      error("Invalid argument #2: Expected UDim2.", 2)
    end

    rawset(self, "Size", udim2)
    self:_update()

    return self
  end

  --- Draw this object, accounting for transparency (in a very poor way)
  -- Recommend using a framebuffer to reduce monitor draw calls.
  -- @treturn {UIControl} self
  function mt.__index.Draw(self)
    expect(1, self, "table")

    -- get position offset.
    local startX, startY = self:GetActualPosition()

    -- determine maximums.
    local maxY = math.min(self.Body.H, self.ActualSize.H)
    local maxX = math.min(self.Body.W, self.ActualSize.W)

    -- actually draw
    for y = 1, maxY do
      for x = 1, maxX do
        local col = self.Body[y]
        if not col then break end
        local pixel = col[x]
        if pixel then
          self.ParentTerm.setCursorPos(startX - 1 + x, startY - 1 + y)
          self.ParentTerm.blit(pixel.C, pixel.FG, pixel.BG)
        end
      end
    end

    -- draw all children
    for i = 1, #self.Children do
      self.Children[i]:Draw()
    end

    return self
  end

  --- Completely empties the body of this UI object.
  -- @treturn {UIControl} self
  function mt.__index.Clear(self)
    expect(1, self, "table")

    rawset(self, "Body", restrictedTable{W = 0, H = 0})

    return self
  end

  --- Flood the background of the UI object with select blit info.
  -- Does not overwrite already written pixels.
  -- @tparam {string} fg The paint-color-code to be used for the text color.
  -- @tparam {string} bg The paint-color-code to be used for the background color.
  -- @tparam {string, nil} c The character to be used (Default ' ' [space]).
  -- @treturn {UIControl} self
  function mt.__index.FloodBackground(self, fg, bg, c)
    expect(1, self, "table")
    expect(2, fg, "string")
    expect(3, bg, "string")
    expect(4, c, "string", "nil")
    c, fg, bg = c and c:sub(1, 1) or ' ', fg:sub(1, 1), bg:sub(1, 1)

    for y = 1, self.ActualSize.H do
      for x = 1, self.ActualSize.W do
        if not self.Body[y] then
          rawset(self.Body, y, restrictedTable{})
        end
        if not self.Body[y][x] then
          rawset(self.Body[y], x, restrictedTable{C = c, FG = fg, BG = bg})
        end
      end
    end
    rawset(self.Body, 'W', self.ActualSize.W)
    rawset(self.Body, 'H', self.ActualSize.H)

    return self
  end

  --- Validate that there are no loops when assigning a new value to the .Parent value
  -- @local
  local function validateNoLoops(uiObject, parent)
    local current = parent
    while current and current.Parent do
      if parent == uiObject then
        error("Cannot assign parent: Loop detected.", 3)
      end
      current = current.Parent
    end
  end

  --- set this uiObject's parent.
  -- Setting parent to nil will cause the parent to be the terminal.
  -- @tparam {UIControl, nil} parent The parent object to be assigned.
  -- @treturn {UIControl} self
  function mt.__index.SetParent(self, parent)
    -- check parent is valid uiobject
    if parent == nil then
      return
    elseif type(parent) ~= "table" or not UIControl.IsValid(parent) then
      error("Cannot assign parent to non-UIObject.", 2)
    end

    -- remove from old parent.
    if self.Parent then
      for i = 1, #self.Parent.Children do
        if self.Parent.Children[i] == self then
          table.remove(self.Parent.Children, i)
        end
      end
    end

    rawset(self, "Parent", parent)
    validateNoLoops(self, parent)

    -- add to new parent, if needed.
    for i = 1, #parent.Children do
      if parent.Children[i] == self then
        return
      end
    end
    table.insert(parent.Children, self)

    return self
  end

  --- Calculate the actual size of this object.
  -- If you just wish to see the actual size without calculating it, use object.ActualSize
  -- @treturn {number} Actual width.
  -- @treturn {number} Actual height.
  function mt.__index.GetActualSize(self)
    expect(1, self, "table")

    -- collect "parent chain"
    local current = self
    local parentChain = {n = 1, self}
    while current and current.Parent do
      parentChain.n = parentChain.n + 1
      parentChain[parentChain.n] = current.Parent
      current = current.Parent
    end

    -- calculate offsets of parents.
    local px, py = 0, 0 -- The topmost parent should not have a parent, so starting at 0, 0 should be fine.
    for i = parentChain.n, 1, -1 do
      px, py = getSizeFromParent(parentChain[i], px, py)
    end

    return px, py
  end

  --- Calculate the actual position of this object.
  -- If you just wish to see the actual position without calculating it, use object.ActualPosition
  -- @treturn number Actual x position, in relation to the terminal.
  -- @treturn number Actual y position, in relation to the terminal.
  function mt.__index.GetActualPosition(self)
    expect(1, self, "table")

    -- collect "parent chain"
    local current = self
    local parentChain = {n = 1, self}
    while current and current.Parent do
      parentChain.n = parentChain.n + 1
      parentChain[parentChain.n] = current.Parent
      current = current.Parent
    end

    -- calculate offsets of parents.
    local px, py = 0, 0 -- The topmost parent should not have a parent, so starting at 0, 0 should be fine.
    for i = parentChain.n, 1, -1 do
      px, py = getPositionFromParent(parentChain[i], px, py)
    end

    return px, py
  end

  --- Get the base size of this object.
  -- @treturn UDim The UDim corresponding to the X axis.
  -- @treturn UDim The UDim corresponding to the Y axis.
  function mt.__index.GetSize()
    return self.Size.X, self.Size.Y
  end

  --- Get the base position of this object.
  -- @treturn UDim The UDim corresponding to the X axis.
  -- @treturn UDim The UDim corresponding to the Y axis.
  function mt.__index.GetPosition()
    return self.Position.X, self.Position.Y
  end

  --- Get the name of this object.
  -- @treturn string The object's name.
  function mt.__index.GetName()
    return self.Name
  end

  --- Get this object's children.
  -- @treturn {UIControl, ...} This object's children.
  function mt.__index.GetChildren(self)
    expect(1, self, "table")
    return self.Children
  end

  --- Search this object for a child named 'name'
  -- @tparam string name The name of the object to search for.
  -- @treturn UIControl|nil The object found, or nil if not.
  function mt.__index.FindFirstChildByName(self, name)
    expect(1, self, "table")
    expect(2, name, "string")

    for i = 1, #self.Children do
      if self.Children[i].Name == name then
        return self.Children[i]
      end
    end

    return nil
  end

  mt.__newindex = blockNewIndex

  -- tostring like function and table, but more info.
  function mt.__tostring(v)
    local x, y = v:GetActualPosition()
    return string.format(
      "%s (%s): X:%d Y:%d W:%d H:%d AX:%d AY:%d",
      v._classname,
      v.Name,
      v.x,
      v.y,
      v.w,
      v.h,
      x,
      y
    )
  end

  uiObject:_update()
  return uiObject
end

return UIControl
