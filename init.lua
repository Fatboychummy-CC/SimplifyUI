local toInject = {
  UDim = require "Objects.UDim",
  UDim2 = require "Objects.UDim2",
  UIControl = require "UIControl"
}

return function(ENV)
  for k, v in pairs(toInject) do
    ENV[k] = v
  end
end
