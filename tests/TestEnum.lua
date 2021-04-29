local Enum = require "Enum"

cctest.newSuite "EnumTests"
  "BuildsInOrder" (function()
    local e = Enum.New {
      "A",
      "B",
      "C",
      "D",
      "E",
      "F"
    }

    EXPECT_EQ(e.A, 1)
    EXPECT_EQ(e.B, 2)
    EXPECT_EQ(e.C, 3)
    EXPECT_EQ(e.D, 4)
    EXPECT_EQ(e.E, 5)
    EXPECT_EQ(e.F, 6)
  end)
