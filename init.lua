local _, selfDir = ...
selfDir = fs.getDir(selfDir)

print("UI system running in directory", selfDir)

package.path = string.format(
  "%s;/%s/?.lua;/%s/?/init.lua",
  package.path,
  selfDir, selfDir
)


_G.Instance = require "Objects.Instance"
_G.UDim     = require "Objects.UDim"
_G.UDim2    = require "Objects.UDim2"
