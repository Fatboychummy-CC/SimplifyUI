local Framework = require "Framework"
local Actor = require "Objects.Actor"

Framework.newSuite "TestActor"
  "N_OK" (function()
    ASSERT_NO_THROW(Actor.Clear)
    ASSERT_EQ(Actor.GetN(), 0)
    Actor.New(function() end)
    ASSERT_EQ(Actor.GetN(), 1)

    ASSERT_NO_THROW(Actor.Clear)
    EXPECT_EQ(Actor.GetN(), 0)
  end)
  "RUNS" (function()
    -- Ensure the actor is empty.
    ASSERT_NO_THROW(Actor.Clear)

    local ran = false

    local coro = coroutine.create(function()
      ran = true
    end)

    parallel.waitForAny(
      Actor.Run,
      function()
        Actor.New(coro)
        os.sleep(0.25)
      end
    )

    EXPECT_TRUE(ran)
    EXPECT_EQ(Actor.GetN(), 0)
  end)
  "RUNS_MULTIPLE" (function()
    -- Ensure the actor is empty.
    ASSERT_NO_THROW(Actor.Clear)

    local ran1, ran2 = false, false

    local coro1 = coroutine.create(function()
      ran1 = true
    end)
    local coro2 = coroutine.create(function()
      ran2 = true
    end)

    parallel.waitForAny(
      Actor.Run,
      function()
        Actor.New(coro1)
        Actor.New(coro2)
        os.sleep(0.25)
      end
    )

    EXPECT_TRUE(ran1)
    EXPECT_TRUE(ran2)

    EXPECT_EQ(Actor.GetN(), 0)
  end)
  "FILTERS_EVENTS" (function()
    Actor.Clear()

    local eventACorrect = false
    local eventBCorrect = false
    local eventA = "AAAAA"
    local eventB = "BBBBB"

    local coro = coroutine.create(function()
      local ev = os.pullEvent(eventA)
      EXPECT_EQ(ev, eventA)
      ev = os.pullEvent(eventB)
      EXPECT_EQ(ev, eventB)
    end)

    parallel.waitForAny(
      Actor.Run,
      function()
        Actor.New(coro)
        os.queueEvent("IncorrectEvent")
        os.queueEvent("EventIncorrect")
        os.queueEvent("IncorrectEvent")
        os.queueEvent(eventA)
        os.queueEvent(eventA)
        os.queueEvent(eventB)

        os.sleep(0.25)
      end
    )
  end)
  "RECEIVES_TERMINATE" (function()
    Actor.Clear()
    local coro = coroutine.create(function()
      os.pullEvent("SomeEvent")
    end)

    local ok, err = pcall(
      parallel.waitForAll,
      function()
        Actor.Run()
      end,
      function()
        os.sleep(0.2)
        os.queueEvent(DUMMY_TERMINATE())
        os.sleep(0.2)
      end
    )

    EXPECT_FALSE(ok)
    EXPECT_EQ(err, "Terminated")
  end)
  "REMOVES_ID" (function()
    Actor.Clear()

    local removed = false

    local coro = coroutine.create(function()
      while true do removed = false os.sleep() end
    end)
    local actorData = Actor.New(coro)

    parallel.waitForAny(
      Actor.Run,
      function()
        removed = true
        Actor.Remove(actorData.actorID)
        os.sleep(1)
      end
    )

    EXPECT_TRUE(removed)
  end)
  "REMOVES_COROUTINE" (function()
    Actor.Clear()

    local removed = false

    local coro = coroutine.create(function()
      while true do removed = false os.sleep() end
    end)
    Actor.New(coro)

    parallel.waitForAny(
      Actor.Run,
      function()
        removed = true
        Actor.Remove(coro)
        os.sleep(1)
      end
    )

    EXPECT_TRUE(removed)
  end)
  "ACTOR_REMOVE_ERRORS" (function()
    EXPECT_THROW_ANY_ERROR(Actor.Remove, "stringValue")
    EXPECT_THROW_ANY_ERROR(Actor.Remove, {})
    EXPECT_THROW_ANY_ERROR(Actor.Remove, function() end)
    EXPECT_THROW_ANY_ERROR(Actor.Remove)
  end)
