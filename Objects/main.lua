--- Random things some objects may need.
-- @module randomThings
-- @alias module

local module = {}

function module.writePrevent(key)
  error(string.format("Cannot write key '%s'.", key), 3)
end

function module.readPrevent(key)
  error(string.format("Cannot read key '%s'.", key), 3)
end

function module.clamp(min, val, max)
  return math.min(max, math.max(min, val))
end

return module
