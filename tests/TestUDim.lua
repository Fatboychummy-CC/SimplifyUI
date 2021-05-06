local UDim = require "UDim"

cctest.newSuite "UDimTests"
  "SetupCorrect" (function()
    local u = UDim.New(0.25, 32)

    EXPECT_EQ(u.Scale, 0.25)
    EXPECT_EQ(u.Offset, 32)
  end)
  "Addition" (function()
    local u  = UDim.New(0.25, 32)
    local u2 = UDim.New(0.25, 32)

    local uF = u + u2

    EXPECT_FLOAT_EQ(uF.Scale, 0.5)
    EXPECT_EQ(uF.Offset, 64)
  end)
  "Subtraction" (function()
    local u  = UDim.New(0.25, 32)
    local u2 = UDim.New(0.25, 32)

    local uF = u - u2

    EXPECT_FLOAT_EQ(uF.Scale, 0)
    EXPECT_EQ(uF.Offset, 0)
  end)
  "Equality" (function()
    local u  = UDim.New(0.25, 32)
    local u2 = UDim.New(0.25, 32)

    EXPECT_EQ(u, u2)
  end)
  "Unequality" (function()
    local u  = UDim.New(0.25, 32)
    local u2 = UDim.New(0.25, 25)
    local u3 = UDim.New(0.5,  32)

    EXPECT_UEQ(u, u2)
    EXPECT_UEQ(u, u3)
    EXPECT_UEQ(u2, u3)
  end)
  "IncorrectTypes" (function()
    local u = UDim.New(0, 0)

    EXPECT_THROW_ANY_ERROR(function()
      u.Scale = "Hello"
    end)
    EXPECT_UEQ(u.Scale, "Hello")
    EXPECT_THROW_ANY_ERROR(function()
      u.Offset = "Hello"
    end)
    EXPECT_UEQ(u.Offset, "Hello")
  end)
  "CorrectTypes" (function()
    local u = UDim.New(0, 0)

    EXPECT_NO_THROW(function()
      u.Scale = 0.5
      u.Offset = 32
    end)
    EXPECT_EQ(u.Scale, 0.5)
    EXPECT_EQ(u.Offset, 32)
  end)
