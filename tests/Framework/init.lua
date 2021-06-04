
-- Calculate the path to self for module requiring.
local modulesPath = ...

-- loop backwards through module path string.
for i = #modulesPath, 1, -1 do
  -- if we find a dot, remove the end of the string up until the dot.
  if modulesPath:sub(i, i) == '.' then
    modulesPath = modulesPath:sub(1, i)
    break
  end

  -- if i is one, we've gone all the way through and haven't found a dot. Add a dot to the end of it.
  if i == 1 then
    modulesPath = modulesPath .. '.'
  end
end



local module = {
  loaded = {},
  tests = {},
}

local expect = require "cc.expect".expect
local strings = require "cc.strings"
local Expectations = require(modulesPath .. "Expectations")
local Test = require(modulesPath .. "Test")
local toInject = {}

-- This functions builds the info line for the current test, ie:
-- [ RUN ] testName
-- [ FAIL] testName
-- [ERROR] testName
-- ... so on
-- generates blit line bg and fg colors as well
local function buildInfoLine(name, status)
  expect(1, name, "string")
  expect(2, status, "number")

  local formatInfo = "[%s]: %s"
  local formatFG = "0%s000%s"
  local formatBG = "f%sfff%s"
  local statusString, statusFG, statusBG
  if status == Test.STATUS.LOADED then
    statusString = "LOAD "
    statusFG = "00000"
    statusBG = "fffff"
  elseif status == Test.STATUS.LOADING then
    statusString = "LDING"
    statusFG = "00000"
    statusBG = "fffff"
  elseif status == Test.STATUS.RUNNING then
    statusString = " RUN "
    statusFG = "00000"
    statusBG = "fffff"
  elseif status == Test.STATUS.OK then
    statusString = "OK   "
    statusFG = "55000"
    statusBG = "fffff"
  elseif status == Test.STATUS.FAIL then
    statusString = " FAIL"
    statusFG = "0eeee"
    statusBG = "fffff"
  elseif status == Test.STATUS.ERROR then
    statusString = "ERROR"
    statusFG = "eeeee"
    statusBG = "fffff"
  else
    statusString = "?????"
    statusFG = "44444"
    statusBG = "fffff"
  end

  return string.format(formatInfo, statusString, name),
         string.format(formatFG, statusFG, string.rep('a', #name)),
         string.format(formatBG, statusBG, string.rep('f', #name))
end

-- write the info about a test.
local function writeInfo(t)
  local xSize = term.getSize()
  local x, y = term.getCursorPos()
  term.setCursorPos(1, y)
  io.write(string.rep(' ', xSize))

  term.setCursorPos(1, y)
  term.blit(buildInfoLine(t.name, t.status))
end

-- if the test failed or errored, print the reason, otherwise just draw a newline
local function finishTest(t)
  print()
  if t.status == Test.STATUS.FAIL then
    print("Test failed:")
    printError(string.format("  %s", table.concat(t.reason, "\n\n  ")))
    print()
    return
  elseif t.status == Test.STATUS.ERROR then
    print("Test failed: Error was thrown in test body.")
    printError(string.format("  %s", table.concat(t.error, "\n\n  ")))
    print()
    return
  end
end

local function generateWrapper(f, isAsserted)
  return function(...)
    local ok, ret = f(...)
    local assertOk = true
    if isAsserted and not ok then assertOk = false end

    return ok, assertOk, ret
  end
end

for k, v in pairs(Expectations) do
  toInject["EXPECT_" .. k] = generateWrapper(v, false)
  toInject["ASSERT_" .. k] = generateWrapper(v, true)
end
toInject.PASS = generateWrapper(function() return true, "" end, false)
toInject.FAIL = generateWrapper(function() return false, "Forceful failure." end, true)

local function countTests()
  local total = 0
  local fails = {
    suites = {n = 0}
  }
  for i = 1, #module.tests do
    for i, test in ipairs(module.tests[i]) do
      if test.status == Test.STATUS.FAIL or test.status == Test.STATUS.ERROR then
        total = total + 1
        if not fails.suites[test.suite] then
          fails.suites[test.suite] = {n = 0}
          fails.suites.n = fails.suites.n + 1
        end
        fails.suites[test.suite].n = fails.suites[test.suite].n + 1
        fails.suites[test.suite][#fails.suites[test.suite] + 1] = test
      end
    end
  end

  return total, fails
end

local function splitOn(a, b)
  local t = {}
  for i = 1, #b do
    local x = a:sub(1, #b[i])
    a = a:sub(#b[i] + 1)
    t[i] = x
  end

  return t
end

function module.runAllTests()
  for i = 1, #module.tests do
    module.runSuite(module.tests[i])
  end

  local total, inSuites = countTests()
  if total == 0 then
    print("All tests passed.")
    return
  end

  local mx, my = term.getSize()
  local c = term.getTextColor()
  term.setTextColor(colors.orange)
  print(string.format("%d test%s failed from %d suite%s.", total, total > 1 and "s" or "", inSuites.suites.n, inSuites.suites.n > 1 and "s" or ""))
  term.setTextColor(c)
  for suiteName, tests in pairs(inSuites.suites) do
    if type(tests) == "table" then
      for i = 1, #tests do
        local txt, fg, bg = "Test %s from %s failed.",
                            "00000%s000000%s00000000",
                            "fffffffffffffffffff%s"
        local testName = tests[i].name
        txt = txt:format(testName, suiteName)
        fg = fg:format(string.rep('a', #testName), string.rep('b', #suiteName))
        bg = bg:format(string.rep('f', #testName + #suiteName))
        txt = strings.wrap(txt, mx - 2)
        fg = splitOn(fg, txt)
        bg = splitOn(bg, txt)

        for i = 1, #txt do
          local x, y = term.getCursorPos()
          term.setCursorPos(3, y)
          term.blit(txt[i], fg[i], bg[i])
          print()
        end
      end
    end
  end
end

function module.runSuite(s)
  local fg, bg, txt = "0000000%s",
                      "fffffff%s",
                      "Suite: %s"
  term.blit(txt:format(s.name), fg:format(string.rep('b', #s.name)), bg:format(string.rep('f', #s.name)))
  print()print()
  for i = 1, #s do
    local currentTest = s[i]
    parallel.waitForAny(
      function()
        while true do
          writeInfo(currentTest)

          os.pullEvent("test_checkpoint")
        end
      end,
      function()
        currentTest:Run(toInject)
      end
    )

    writeInfo(currentTest)
    finishTest(currentTest)
  end
  print()
end

function module.newSuite(suiteName)
  local suite = {finished = false, name = suiteName}
  module.tests[#module.tests + 1] = suite

  local currentName, loadBody

  -- Load the name into memory
  local function loadName(name)
    expect(1, name, "string")
    suite.finished = false

    currentName = name

    return loadBody
  end

  -- Load the body, then create the test and add it to the suite.
  loadBody = function(f)
    if type(f) == "table" then
      f = f[1]
    end
    expect(1, f, "table", "function")

    suite[#suite + 1] = Test.new(f, currentName, suiteName)

    suite.finished = true
    return loadName
  end

  -- return the name loader.
  return loadName
end

return module
