local expect = require "cc.expect".expect
local unpack = table.unpack
local remove = table.remove

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
      remove(actorRunOrder, i)
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
        return data
      end
    end,
    Available = function(self)
      expect(1, self, "table")

      return self.callData.n > 0
    end,
    Register = function(self, event, registrationName, callback)
      expect(1, self, "table")
      expect(2, event, "string")
      expect(3, registrationName, "string")
      expect(4, callback, "function")

      -- Check if the table exists already.
      local t = self.registrations[event]
      if not t then -- create it if it doesn't.
        self.registrations[event] = {n = 0}
        t = self.registrations[event]
      end

      -- insert the item.
      t.n = t.n + 1
      t[t.n] = {registrationName, callback}
    end,
    DeRegister = function(self, event, registrationName)
      expect(1, self, "table")
      expect(2, event, "string")
      expect(3, registrationName, "string")

      -- check if it exists
      local t = self.registrations[event]
      if t and t.n > 0 then
        -- if it does, loop and find registrationName
        for i = 1, t.n do
          if t[i][1] == registrationName then
            local tmp = remove(t, i) -- if we find it, remove it.
            if tmp then -- error checking, this shouldn't be needed but just checking if the item was *actually* removed.
              t.n = t.n - 1
            end
          end
        end
      end
    end
  },
  __call = function(self, ...)
    expect(1, self, "table")

    self:Call(...)
  end
}

--- Create a new actor.
function Actor.New()
  local actorData = setmetatable({
    callData = {n = 0},
    registrations = {n = 0}
  }, actorObjectMetaTable)

  local actorID = InsertActor(actorData)
  actorData.actorID = actorID

  -- create the actor's coroutine.
  local function actorCoroutineFunction()
    local yield = coroutine.yield
    local unpack = table.unpack
    while true do
      local data = yield() -- guarantee: event data will be packed to a table already.
      local regs = actorData.registrations[data[1]]
      if regs then
        for i = 1, regs.n do
          regs[i][2](unpack(data, 2, data.n))
        end
      end
    end
  end

  actorData.coroutine = coroutine.create(actorCoroutineFunction)
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
  local resume, status = coroutine.resume, coroutine.status

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

      repeat
        -- if the actor is listening for a specific event (and it matches that event), or the actor is listening for any event...
        if actor and actor.events and actor.events[event] or actor and actor:Available() then
          -- resume the coroutine with the event data.
          local ok, result = resume(actor.coroutine, unpack(eventData, 1, eventData.n))

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
          if status(actor.coroutine) == "dead" then
            actorsToRemove.n = actorsToRemove.n + 1
            actorsToRemove[actorsToRemove.n] = actorID
          end
        end

        local available = actor:Available() -- check if the actor has any messages in the queue
        if available then
          eventData = actor:Read()
          event = eventData[1]
        end
      until not available
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
