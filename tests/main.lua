package.path = package.path .. ";/UI/?.lua;/UI/?/init.lua"

local cctest = require "Framework"
_G.cctest = cctest

require "TestActor"

cctest.runAllTests(...)
