--- Simple Enums.
-- @author fatboychummy
-- @type Enum

local expect = require "cc.expect".expect

local Enum = {}

--- Create a new Enum.
-- @tparam string ... Enum item names.
-- @treturn Enum
function Enum.New(...)
  local args = table.pack(...)
  if type(args[1]) == "table" then
    args = args[1]
    args.n = #args
  end
  local enum = {}

  for i = 1, args.n do
    expect(i, args[i], "string")
    enum[args[i]] = i
  end

  return enum
end

return Enum
