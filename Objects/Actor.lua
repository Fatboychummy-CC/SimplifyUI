local expect = require "cc.expect".expect

local Actor = {}

local actors = {n = 0}
local function InsertActor(actor)
  actors.n = actors.n + 1
  actors[actors.n] = actor
end
local function RemoveActor(actor)
  for i = 1, actors.n do
    if actor == actors[i] then
      table.remove(actors, i)
      actors.n = actors.n - 1
      return
    end
  end
end

--- Create a new actor.
function Actor.New(coro)
  expect(coro, 1, "thread", "function")

  -- Convert function to a coroutine, if required.
  coro = type(coro) == "function" and coroutine.create(coro) or coro

  local actorData = {
    coroutine = coro
  }

  InsertActor(actorData)
  os.queueEvent("new_actor")
end

--- Run all the coroutines.
function Actor.Run(yieldFunc)
  yieldFunc = yieldFunc or coroutine.yield

  while true do
    local eventData = table.pack(yieldFunc())
    local event = eventData[1]

    -- loop through each actor and pass event data to them, if wanted.
    for i = 1, actors.n do
      -- if the actor is listening for a specific event (and it matches that event), or the actor is listening for any event...
      if actor.listening and actor.listening == event or not actor.listening then
        -- resume the coroutine with the event data.
        local ok, result = coroutine.resume(actor.coroutine, table.unpack(eventData, 1, eventData.n))

        -- If the coroutine errored, error.
        if not ok then
          error(string.format("Actor threw an error: %s", result), -1)
        end

        -- assign the actor to listen for whatever they wanted to listen for.
        actor.listening = result

        -- If the actor is now dead, remove it.
        if coroutine.status(actor.coroutine) == "dead" then
          RemoveActor(actor)
        end
      end
    end
  end
end

return Actor
