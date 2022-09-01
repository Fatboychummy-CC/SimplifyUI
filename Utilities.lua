local expect = require "cc.expect".expect

local Utilities = {}

function Utilities.Lerp(a, b, alpha)
  return a * (1-alpha) + b * alpha
end

return Utilities