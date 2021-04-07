--- UIControl is what every uiobject inherits from.
-- @author fatboychummy
-- @type UIControl
-- @alias mt


local UIControl = {}
local expect = require "cc.expect".expect
local UDim, UDim2 = require "Objects.UDim", require "Objects.UDim2"

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

  local mt = {__index = {}}
  local deepmt = {__index = {}}

  local function restrictedTable(t)
    return setmetatable(t or {}, deepmt)
  end

  local uiObject = setmetatable({
    -- class info
    _classname = "UIControl",
    _name = name,
    _isUIObject = true,

    -- positioning
    Position = UDim2.FromOffset(x or 0, y or 0),
    Size = UDim2.FromOffset(w or 0, h or 0),
    AnchorPoint = UDim2.New(0, 0, 0, 0),

    -- "local" positioning: Position the object will actually be drawn at
    -- determined in _update function.
    ActualPosition = restrictedTable{X = x or 0, Y = y or 0},
    ActualSize = restrictedTable{W = w or 0, H = h or 0},

    -- object information
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

  --- Get the actual size of this object.
  --
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

  -- Recursive function that traverses parents until parent is nil. Then,
  -- collects all the offsets and sizes to calculate this object's position.
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

  -- Draw this object, accounting for transparency (in a very poor way)
  -- Recommend using a framebuffer to reduce monitor draw calls.
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

  function mt.__index.Clear(self)
    expect(1, self, "table")

    rawset(self, "Body", restrictedTable{W = 0, H = 0})

    return self
  end

  function mt.__index.FloodBackground(self, c, fg, bg)
    expect(1, self, "table")
    expect(2, c, "string")
    expect(3, fg, "string")
    expect(4, bg, "string")
    c, fg, bg = c:sub(1, 1), fg:sub(1, 1), bg:sub(1, 1)

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
  end

  -- Check for loops when assigning a new parent.
  local function validateNoLoops(uiObject, parent)
    local current = parent
    while current and current.Parent do
      if parent == uiObject then
        error("Cannot assign parent: Loop detected.", 3)
      end
      current = current.Parent
    end
  end

  -- set this uiObject's parent.
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

  -- get the size of this object.
  function mt.__index.GetSize()
    return w, h
  end

  -- Return all the children.
  function mt.__index.GetChildren(self)
    expect(1, self, "table")
    return self.Children
  end

  -- Return the first child with name 'name'
  function mt.__index.FindFirstChildByName(self, name)
    expect(1, self, "table")
    expect(2, name, "string")

    for i = 1, #self.Children do
      if self.Children[i]._name == name then
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
      v._name,
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
