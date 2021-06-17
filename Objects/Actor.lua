local expect = require "cc.expect".expect

local Actor = {}

local actors = {lastID = 0}
local actorRunOrder = {n = 0}
local function InsertActor(actorData)
  -- create the actor data
  actors.lastID = actors.lastID + 1
  actors[actors.lastID] = actorData

  -- add actor to runorder
  actorRunOrder.n = actorRunOrder.n + 1
  actorRunOrder[actorRunOrder.n] = actors.lastID

  -- return the id of this actor
  return actors.lastID
end

local function RemoveActor(actorID)
  expect(1, actorID, "number")

  actors[actorID] = nil
  for i = 1, actorRunOrder.n do
    if actorRunOrder[i] == actorID then
      table.remove(actorRunOrder, i)
      return
    end
  end
end

--- Create a new actor.
function Actor.New(coro)
  expect(1, coro, "thread", "function")

  -- Convert function to a coroutine, if required.
  coro = type(coro) == "function" and coroutine.create(coro) or coro

  local actorData = {
    coroutine = coro
  }

  local actorID = InsertActor(actorData)
  actorData.actorID = actorID
  os.queueEvent("new_actor")

  return actorData
end

function Actor.GetN()
  local count = -1 -- init at -1 to "uncount" the `lastID` value.
  for _ in pairs(actors) do
    count = count + 1
  end
  return count
end

function Actor.Clear()
  local ids = {}
  for id in pairs(actors) do if type(id) == "number" then ids[#ids + 1] = id end end
  for i = 1, #ids do
    RemoveActor(ids[i])
  end
end

function Actor.Remove(coro)
  expect(1, coro, "thread", "number")

  if type(coro) == "number" then
    RemoveActor(coro)
    return
  end

  for id, actor in pairs(actors) do
    if type(actor) == "table" and actor.coroutine == coro then
      RemoveActor(id)
      return
    end
  end
end

--- Run all the coroutines.
function Actor.Run(yieldFunc, main)
  yieldFunc = yieldFunc or coroutine.yield
  expect(1, yieldFunc, "function")
  expect(2, main, "function", "thread", "nil")
  local hasMain, mainID = false, 0

  -- If the player inserted a func or coroutine to main, insert it as an actor to be run.
  if type(main) == "function" or type(main) == "thread" then
    local actorData = {
      coroutine = type(main) == "function" and coroutine.create(main) or main
    }

    hasMain = true
    mainID = InsertActor(actorData)
  end

  -- Main loop - Run stuff forever.
  while true do
    local eventData = table.pack(yieldFunc())
    local event = eventData[1]
    local actorsToRemove = {n = 0}

    -- loop through each actor and pass event data to them, if wanted.
    for i = 1, actorRunOrder.n do
      local actorID = actorRunOrder[i]
      local actor = actors[actorID]

      -- if the actor is listening for a specific event (and it matches that event), or the actor is listening for any event...
      if actor and (actor.listening and actor.listening == event or not actor.listening) then
        -- resume the coroutine with the event data.
        local ok, result = coroutine.resume(actor.coroutine, table.unpack(eventData, 1, eventData.n))

        -- If the coroutine errored, error.
        if not ok then
          error(
            string.format(
              "Actor: Actor '%s' threw an error: %s",
              actorID == mainID and "Main Thread" or actorID,
              result),
            -1
          )
        end

        -- assign the actor to listen for whatever they wanted to listen for.
        actor.listening = result

        -- If the actor is now dead, remove it.
        if coroutine.status(actor.coroutine) == "dead" then
          actorsToRemove.n = actorsToRemove.n + 1
          actorsToRemove[actorsToRemove.n] = actorID
        end
      end
    end

    -- Actually remove the dead coroutine
    for i = actorsToRemove.n, 1, -1 do
      RemoveActor(actorsToRemove[i])
    end

    -- If the main thread has died for whichever reason, stop.
    if hasMain and not actors[mainID] then
      error("Actor: Main thread has stopped.", -1)
    end
  end
end

return Actor
