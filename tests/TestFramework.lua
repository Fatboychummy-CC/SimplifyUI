package.path = package.path .. ";/UI/tests/?.lua;/UI/Objects/?.lua;/UI/?.lua;/?.lua"

local cctest = require "Framework"
_G.cctest = cctest

cctest.newSuite "TestSuiteName"
  "SomeRandomTest" {
    function()
      PASS()
    end
  }
  "SomeOtherTest" (
    function()
      FAIL()
    end
  )

cctest.runAllTests()
