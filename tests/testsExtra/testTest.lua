package.path = package.path .. ";UI/tests/?.lua;UI/Objects/?.lua"

local cctest = require "Framework"

local function deepCopy(t)
  local t2 = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      t2[k] = deepCopy(v)
    else
      t2[k] = v
    end
  end

  return t2
end

local suite = cctest.newSuite "TestExpectations" {
  EXPECT_EQ_PASS = function()
    EXPECT_EQ(10, 10)
  end,
  EXPECT_EQ_FAIL = function()
    EXPECT_EQ(10, 5)
  end,
  EXPECT_UEQ_PASS = function()
    EXPECT_UEQ(10, 5)
  end,
  EXPECT_UEQ_FAIL = function()
    EXPECT_UEQ(10, 10)
  end,
  EXPECT_FLOAT_EQ_PASS = function()
    local n = math.random(1, 100000000) / 100000000
    EXPECT_FLOAT_EQ(n, n)
  end,
  EXPECT_FLOAT_EQ_FAIL = function()
    local n = math.random(1, 100000000) / 100000000
    EXPECT_FLOAT_EQ(n, n - 0.000005)
  end,
  EXPECT_FLOAT_EQ_FAIL2 = function()
    local n = math.random(1, 100000000) / 100000000
    EXPECT_FLOAT_EQ(n, n, "A")
  end,
  EXPECT_DEEP_TABLE_EQ_PASS = function()
    local t1 = {{},{y = "No"},{},n = 43, ["Noot Noot"] = {x = 64, {}}}
    local t2 = deepCopy(t1)

    EXPECT_DEEP_TABLE_EQ(t1, t2)
  end,
  EXPECT_DEEP_TABLE_EQ_FAIL1 = function()
    local t1 = {{},{y = "No"},{},n = 43, ["Noot Noot"] = {x = 64, {}}}
    local t2 = deepCopy(t1)
    t1.sdadsa = ""

    EXPECT_DEEP_TABLE_EQ(t1, t2)
  end,
  EXPECT_DEEP_TABLE_EQ_FAIL2 = function()
    local t1 = {{},{y = "No"},{},n = 43, ["Noot Noot"] = {x = 64, {}}}
    local t2 = deepCopy(t1)
    t2.sdadsa = ""

    EXPECT_DEEP_TABLE_EQ(t1, t2)
  end,
  EXPECT_TRUE_PASS = function()
    EXPECT_TRUE(true)
  end,
  EXPECT_TRUE_FAIL = function()
    EXPECT_TRUE(false)
  end,
  EXPECT_FALSE_PASS = function()
    EXPECT_FALSE(false)
  end,
  EXPECT_FALSE_FAIL = function()
    EXPECT_FALSE(true)
  end,
  EXPECT_TRUTHY_PASS_ALL = function()
    EXPECT_TRUTHY(true)
    EXPECT_TRUTHY("A")
    EXPECT_TRUTHY(3)
    EXPECT_TRUTHY({})
  end,
  EXPECT_TRUTHY_FAIL = function()
    EXPECT_TRUTHY(nil)
  end,
  EXPECT_FALSEY_FAIL1 = function()
    EXPECT_FALSEY(true)
  end,
  EXPECT_FALSEY_FAIL2 = function()
    EXPECT_FALSEY(3)
  end,
  EXPECT_FALSEY_FAIL3 = function()
    EXPECT_FALSEY("a")
  end,
  EXPECT_FALSEY_FAIL4 = function()
    EXPECT_FALSEY({})
  end,
  EXPECT_THROW_PASS = function()
    EXPECT_THROW_ANY_ERROR(function()
      error("Hello there.")
    end)
  end,
  EXPECT_THROW_FAIL = function()
    EXPECT_THROW_ANY_ERROR(function() end)
  end,
  EXPECT_THROW_FAIL2 = function()
    EXPECT_THROW_ANY_ERROR()
  end,
  EXPECT_THROW_MATCHED_ERROR_PASS = function()
    EXPECT_THROW_MATCHED_ERROR(function()
      error("Test Test 123")
    end, "Test Test %d+")
  end,
  EXPECT_THROW_MATCHED_ERROR_FAIL = function()
    EXPECT_THROW_MATCHED_ERROR(function()
      error("Test Test 123")
    end, "Test Test a")
  end,
  EXPECT_THROW_MATCHED_ERROR_FAIL2 = function()
    EXPECT_THROW_MATCHED_ERROR(function() end)
  end,
  EXPECT_THROW_MATCHED_ERROR_FAIL3 = function()
    EXPECT_THROW_MATCHED_ERROR()
  end,
  EXPECT_NO_THROW_PASS = function()
    EXPECT_NO_THROW(function() end)
  end,
  EXPECT_NO_THROW_FAIL = function()
    EXPECT_NO_THROW(function() error("Yeet") end)
  end,
  EXPECT_NO_THROW_FAIL2 = function()
    EXPECT_NO_THROW()
  end,
}

local suite2 = cctest.newSuite "AssertionTests" {
  DOES_NOT_RUN_PAST = function()
    ASSERT_EQ(10, 5) -- Should stop here.
    error("This should not be thrown.")
  end
}

local suite3 = cctest.newSuite "Short" {
  SHORT_NAME = function()
    ASSERT_EQ(10, 5) -- Should stop here.
    error("This should not be thrown.")
  end,
  EVEN_SHORTER_NAME = function()
    FAIL()
  end
}

cctest.runAllTests()
