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

local actorObjectMetaTable = {
  __index = {
    -- adds
    CallFriend = function(self, actorID, ...)
      expect(1, self, "table")
      expect(2, actorID, "number")
      if actors[actorID] then
        actors[actorID]:Call(self.actorID, ...)
      end
    end,
    Call = function(self, ...)
      expect(1, self, "table")

      self.callData.n = self.callData.n + 1
      self.callData[self.callData.n] = table.pack(...)
    end,
    Read = function(self)
      expect(1, self, "table")

      local data = table.remove(self.callData, 1)
      if data then
        self.callData.n = self.callData.n - 1
        return table.unpack(data, 1, data.n)
      end
    end,
    Available = function(self)
      expect(1, self, "table")

      return self.callData.n > 0
    end
  },
  __call = function(self, ...)
    self:Call(...)
  end
}

--- Create a new actor.
function Actor.New(coro, yieldFunc)
  expect(1, coro, "thread", "function")
  expect(2, yieldFunc, "function", "nil")

  -- Convert function to a coroutine, if required.
  coro = type(coro) == "function" and coroutine.create(coro) or coro

  local actorData = setmetatable({
    coroutine = coro,
    callData = {n = 0},
    yieldFunc = yieldFunc
  }, actorObjectMetaTable)

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
      if actor and (actor.filter and actor.filter == event or not actor.filter) then
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
        actor.filter = result

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
