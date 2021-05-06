local BasicClass = require "BasicClass"

cctest.newSuite "TestBasicClass"
  "PropertyChangeEvents" (
    function()
      local x = BasicClass.New("x", {}, {
        xyz = 32,
        abc = 64
      })

      EXPECT_EVENT(
        function()
          x.xyz = 128
        end,
        x.PropertyChangedEvent.Name,
        0.25
      )
      EXPECT_EVENT(
        function()
          x.abc = 128
        end,
        x.PropertyChangedEvent.Name,
        0.25
      )
    end
  )
  "RemovedEvents" (
    function()
      local x = BasicClass.New("x", {}, {})
      EXPECT_EVENT(
        x.Remove,
        x.RemovingEvent.Name,
        0.25,
        x
      )
    end
  )
  "NewSettable" (
    function()
      local x = BasicClass.New("x", {}, {}, true)
      local function xyz() end
      x:New(xyz)

      EXPECT_EQ(x.New, xyz)
    end
  )
  "ClassName" (
    function()
      local className = "derp"
      local x = BasicClass.New(className, {}, {})

      EXPECT_EQ(x.ClassName, className)
    end
  )
