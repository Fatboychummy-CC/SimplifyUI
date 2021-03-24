local UIControl = {}
local expect = require "cc.expect".expect

function UIControl.isValid(t)
  return type(t) == "table" and t.isUIObject
end

function UIControl.new(parentTerm, x, y, w, h, name, parent)
  expect(1, parentTerm, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, w, "number")
  expect(5, h, "number")
  expect(6, name, "string")
  expect(7, parent, "table", "nil")
  if parent and not UIControl.isValid(parent) then
    error("Cannot assign parent to non-UIObject.", 2)
  end

  local mt = {__index = {}}
  local deepmt = {__index = {}}

  local function restrictedTable(t)
    return setmetatable(t or {}, deepmt)
  end

  local uiObject = setmetatable({
    classname = "UIControl",
    x = x,
    y = y,
    w = w,
    h = h,
    body = restrictedTable{w = 0, h = 0},
    parentTerm = parentTerm,
    parent = parent,
    children = restrictedTable{},
    name = name,
    isUIObject = true,
    pivot = restrictedTable{0, 0},
    anchor = restrictedTable{0, 0}
  }, mt)

  local function blockNewIndex()
    error("Assigning manually is restricted. Use setter methods instead.", 2)
  end

  deepmt.__newindex = blockNewIndex

  -- Crawl backwards through list of parents.
  -- Get location this object should be drawn at.
  --
  local function getLocalPosition(uiObject, px, py)
    local ox, oy = uiObject:getSize()
    if not uiObject.parent then -- if root object
      local tx, ty = term.getSize()
      return math.floor(tx * uiObject.anchor[1] + 0.5) - math.floor((ox - 1) * uiObject.pivot[1] + 0.5) + uiObject.x,
             math.floor(ty * uiObject.anchor[2] + 0.5) - math.floor((oy - 1) * uiObject.pivot[2] + 0.5) + uiObject.y
    else -- NOT root object.
      local tx, ty = uiObject.parent:getSize()
      return math.floor(tx * uiObject.anchor[1] + 0.5) - math.floor((ox - 1) * uiObject.pivot[1] + 0.5) + px + uiObject.x,
             math.floor(ty * uiObject.anchor[2] + 0.5) - math.floor((oy - 1) * uiObject.pivot[2] + 0.5) + py + uiObject.y
    end
  end

  -- Recursive function that traverses parents until parent is nil. Then,
  -- collects all the offsets and sizes to calculate this object's position.
  function mt.__index.getLocalPosition(self)
    expect(1, self, "table")

    -- collect "parent chain"
    local current = self
    local parentChain = {n = 1, self}
    while current and current.parent do
      parentChain.n = parentChain.n + 1
      parentChain[parentChain.n] = current.parent
      current = current.parent
    end

    -- calculate offsets of parents.
    local px, py = 1, 1
    for i = parentChain.n, 1, -1 do
      px, py = getLocalPosition(parentChain[i], px, py)
    end

    return px, py
  end

  function mt.__index.getPivotPoint(self)
    expect(1, self, "table")

    local x, y = self:getLocalPosition()
    return x + math.floor(self.pivot[1] * (self.w - 1) + 0.5), y + math.floor(self.pivot[2] * (self.h - 1) + 0.5)
  end

  function mt.__index.resize(self, w, h)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")

    rawset(self, 'w', w)
    rawset(self, 'h', h)

    return self
  end

  -- reposition this object.
  function mt.__index.reposition(self, x, y)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")

    rawset(self, 'x', x)
    rawset(self, 'y', y)

    return self
  end

  --TODO: make children x/y pos an offset of their parents, rather than absolute.

  -- Draw this object, accounting for transparency (in a very poor way)
  -- Recommend using a framebuffer to reduce monitor draw calls.
  function mt.__index.draw(self)
    expect(1, self, "table")

    -- get position offset.
    local startX, startY = self:getLocalPosition()

    -- determine maximums.
    local maxY = math.min(self.body.h, self.h)
    local maxX = math.min(self.body.w, self.w)

    -- actually draw
    for y = 1, maxY do
      for x = 1, maxX do
        local col = self.body[y]
        if not col then break end
        local pixel = col[x]
        if pixel then
          self.parentTerm.setCursorPos(startX - 1 + x, startY - 1 + y)
          self.parentTerm.blit(pixel.c, pixel.fg, pixel.bg)
        end
      end
    end

    -- draw all children
    for i = 1, #self.children do
      self.children[i]:draw()
    end

    return self
  end

  local function Between0and1(val, arg, funcName)
    if val < 0 or val > 1 then
      error(string.format("Bad argument #%d to %s: Expected number between 0 and 1.", arg, funcName))
    end
  end

  function mt.__index.clear(self)
    expect(1, self, "table")

    rawset(self, "body", restrictedTable{w = 0, h = 0})

    return self
  end

  function mt.__index.floodBackground(self, c, fg, bg)
    expect(1, self, "table")
    expect(2, c, "string")
    expect(3, fg, "string")
    expect(4, bg, "string")
    c, fg, bg = c:sub(1, 1), fg:sub(1, 1), bg:sub(1, 1)

    for y = 1, self.h do
      for x = 1, self.w do
        if not self.body[y] then
          rawset(self.body, y, restrictedTable{})
        end
        if not self.body[y][x] then
          rawset(self.body[y], x, restrictedTable{c = c, fg = fg, bg = bg})
        end
      end
    end
    rawset(self.body, 'w', self.w)
    rawset(self.body, 'h', self.h)
  end

  function mt.__index.setAnchor(self, x, y)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    Between0and1(x, 2, "UIWindow.setAnchor")
    Between0and1(y, 3, "UIWindow.setAnchor")

    rawset(self, "anchor", restrictedTable{x, y})

    return self
  end

  function mt.__index.setPivot(self, x, y)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    Between0and1(x, 2, "UIWindow.setPivot")
    Between0and1(y, 3, "UIWindow.setPivot")

    rawset(self, "pivot", restrictedTable{x, y})

    return self
  end

  -- Check for loops when assigning a new parent.
  local function validateNoLoops(uiObject, parent)
    local current = parent
    while current and current.parent do
      if parent == uiObject then
        error("Cannot assign parent: Loop detected.", 3)
      end
      current = current.parent
    end
  end

  -- set this uiObject's parent.
  function mt.__index.setParent(self, parent)
    -- check parent is valid uiobject
    if parent == nil then
      return
    elseif type(parent) ~= "table" or not UIControl.isValid(parent) then
      error("Cannot assign parent to non-UIObject.", 2)
    end

    -- remove from old parent.
    if self.parent then
      for i = 1, #self.parent.children do
        if self.parent.children[i] == self then
          table.remove(self.parent.children, i)
        end
      end
    end

    rawset(self, "parent", parent)
    validateNoLoops(self, parent)

    -- add to new parent, if needed.
    for i = 1, #parent.children do
      if parent.children[i] == self then
        return
      end
    end
    table.insert(parent.children, self)

    return self
  end

  -- get the size of this object.
  function mt.__index.getSize()
    return w, h
  end

  -- Return all the children.
  function mt.__index.getChildren(self)
    expect(1, self, "table")
    return self.children
  end

  -- Return the first child with name 'name'
  function mt.__index.findFirstChildByName(self, name)
    expect(1, self, "table")
    expect(2, name, "string")

    for i = 1, #self.children do
      if self.children[i].name == name then
        return self.children[i]
      end
    end

    return nil
  end

  mt.__newindex = blockNewIndex

  -- tostring like function and table, but more info.
  function mt.__tostring(v)
    local x, y = v:getLocalPosition()
    return string.format(
      "%s (%s): X:%d Y:%d W:%d H:%d LX:%d LY:%d | Anchor: %.2f %.2f Pivot: %.2f %.2f",
      v.classname,
      v.name,
      v.x,
      v.y,
      v.w,
      v.h,
      x,
      y,
      v.anchor[1],
      v.anchor[2],
      v.pivot[1],
      v.pivot[2]
    )
  end

  return uiObject
end

return UIControl
