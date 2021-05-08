package.path = package.path .. ";/UI/tests/?.lua;/UI/Objects/?.lua;/UI/?.lua;/?.lua"

local cctest = require "Framework"
_G.cctest = cctest

require "TestBasicClass"
require "TestEnum"
require "TestUDim"
require "TestUDim2"
require "TestUIControl"

cctest.runAllTests()
