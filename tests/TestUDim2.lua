local UDim2 = require "UDim2"
local UDim = require "UDim"

cctest.newSuite "UDim2Tests"
  "SetupCorrect" (function()
    local xS, xO, yS, yO = 0.5, 32, 0.75, 64
    local u = UDim2.New(xS, xO, yS, yO)

    EXPECT_EQ(u.X.Scale,  xS)
    EXPECT_EQ(u.X.Offset, xO)
    EXPECT_EQ(u.Y.Scale,  yS)
    EXPECT_EQ(u.Y.Offset, yO)
  end)
  "Addition" (function()
    local xS1, xO1, yS1, yO1, xS2, xO2, yS2, yO2
       = 0.25,  32, 0.5,  32, 0.5,  64, 0.3,  71

    local u, u2 = UDim2.New(xS1, xO1, yS1, yO1), UDim2.New(xS2, xO2, yS2, yO2)

    local u3 = u + u2

    EXPECT_EQ(u3.X.Scale,  xS1 + xS2)
    EXPECT_EQ(u3.X.Offset, xO1 + xO2)
    EXPECT_EQ(u3.Y.Scale,  yS1 + yS2)
    EXPECT_EQ(u3.Y.Offset, yO1 + yO2)
  end)
  "Subtraction" (function()
    local xS1, xO1, yS1, yO1, xS2, xO2, yS2, yO2
       = 0.25,  32, 0.5,  32, 0.5,  64, 0.3,  71

    local u, u2 = UDim2.New(xS1, xO1, yS1, yO1), UDim2.New(xS2, xO2, yS2, yO2)
    local u3 = u - u2

    EXPECT_EQ(u3.X.Scale,  xS1 - xS2)
    EXPECT_EQ(u3.X.Offset, xO1 - xO2)
    EXPECT_EQ(u3.Y.Scale,  yS1 - yS2)
    EXPECT_EQ(u3.Y.Offset, yO1 - yO2)
  end)
  "Equality" (function()
    local xS, xO, yS, yO = 0.5, 32, 0.75, 64
    local u, u2 = UDim2.New(xS, xO, yS, yO), UDim2.New(xS, xO, yS, yO)

    EXPECT_EQ(u, u2)
  end)
  "Unequality" (function()
    local xS, xO, yS, yO = 0.5, 32, 0.75, 64
    local u, u2, u3, u4, u5 = UDim2.New(xS, xO, yS, yO),
                              UDim2.New(xS + 0.1, xO, yS, yO),
                              UDim2.New(xS, xO + 1, yS, yO),
                              UDim2.New(xS, xO, yS + 0.1, yO),
                              UDim2.New(xS, xO, yS, yO + 1)

    EXPECT_UEQ(u, u2)
    EXPECT_UEQ(u, u3)
    EXPECT_UEQ(u, u4)
    EXPECT_UEQ(u, u5)

    EXPECT_UEQ(u2, u3)
    EXPECT_UEQ(u2, u4)
    EXPECT_UEQ(u2, u5)

    EXPECT_UEQ(u3, u4)
    EXPECT_UEQ(u3, u5)

    EXPECT_UEQ(u4, u5)
  end)
  "IncorrectTypes" (function()
    local u = UDim2.New(0, 0, 0, 0)
    EXPECT_THROW_ANY_ERROR(function()
      u.X = 32
    end)
    EXPECT_UEQ(u.X, 32)
    EXPECT_THROW_ANY_ERROR(function()
      u.Y = 32
    end)
    EXPECT_UEQ(u.Y, 32)
  end)
  "CorrectTypes" (function()
    local u = UDim2.New(0, 0, 0, 0)
    local comparator = UDim.New(1, 1)
    EXPECT_NO_THROW(function()
      u.X = comparator
    end)
    EXPECT_EQ(u.X, comparator)
    EXPECT_NO_THROW(function()
      u.Y = comparator
    end)
    EXPECT_EQ(u.Y, comparator)
  end)
  "FromScaleConstructor" (function()
    local u
    local xScale, yScale = 0.1, 0.2
    EXPECT_NO_THROW(function() u = UDim2.FromScale(xScale, yScale) end)
    EXPECT_EQ(u.X.Scale, xScale)
    EXPECT_EQ(u.Y.Scale, yScale)
  end)
  "FromOffsetConstructor" (function()
    local u
    local xScale, yScale = 25, 481
    EXPECT_NO_THROW(function() u = UDim2.FromOffset(xScale, yScale) end)
    EXPECT_EQ(u.X.Offset, xScale)
    EXPECT_EQ(u.Y.Offset, yScale)
  end)
