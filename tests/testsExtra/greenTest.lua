package.path = package.path .. ";UI/tests/?.lua;UI/Objects/?.lua"

local cctest = require "Framework"

local function waitRandom()
  os.sleep(math.random(50, 300) / 200)
end

local suite = cctest.newSuite "EverythingPassesBeautifully" {
  PASS1 = function() waitRandom() PASS() end,
  PASS2 = function() waitRandom() PASS() end,
  PASS3 = function() waitRandom() PASS() end,
  PASS4 = function() waitRandom() PASS() end,
  PASS5 = function() waitRandom() PASS() end,
  PASS6 = function() waitRandom() PASS() end,
  PASS7 = function() waitRandom() PASS() end,
  PASS11 = function() waitRandom() PASS() end,
  PASS21 = function() waitRandom() PASS() end,
  PASS31 = function() waitRandom() PASS() end,
  PASS41 = function() waitRandom() PASS() end,
  PASS51 = function() waitRandom() PASS() end,
  PASS61 = function() waitRandom() PASS() end,
  PASS71 = function() waitRandom() PASS() end,
  FAIL_XD_REKT_NOOB = function() waitRandom() FAIL() end
}

cctest.runAllTests()
