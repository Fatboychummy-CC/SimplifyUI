---@author Fatboychummy
---@meta

local expect = require "cc.expect".expect

local Utilities = {}

---@param a number The value to lerp from.
---@param b number The value to lerp to.
---@param alpha number The point gotten between a and b (0-1)
function Utilities.Lerp(a, b, alpha)
  return a * (1-alpha) + b * alpha
end

return Utilities