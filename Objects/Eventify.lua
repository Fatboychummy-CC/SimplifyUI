local expect = require "cc.expect".expect

local tConnections = {}

local function eventify(sEvent)
  expect(1, sEvent, "string")
  return {
      Name = sEvent,

      --[[
        @function Event:Fire fires the event
        @params event arguments
        @part-of eventify
      ]]
      Fire = function(self, ...)
        if tConnections[sEvent] then
          for i = 1, #tConnections[sEvent] do
            tConnections[sEvent][i](...)
          end
        end
        os.queueEvent(self.Name)
      end,

      --[[
        @function Event:Wait waits for an event to occur, then returns it and it's data
        @param self the event
        @param nTimeout timeout, in seconds
        @returns any If the event was received
        @returns nil If the timeout was hit
        @partof eventify
      ]]
      Wait = function(self, nTimeout)
        expect(1, self, "table")
        expect(2, nTimeout, "number", "nil")

        if nTimeout then
          nTimeout = os.startTimer(nTimeout)
        end
        while true do
          local tEvent = table.pack(os.pullEvent())
          if tEvent[1] == "timer" and tEvent[2] == nTimeout then
            return
          elseif tEvent[1] == sEvent then
            return table.unpack(tEvent, 2, tEvent.n)
          end
        end
      end,

      --[[
        @function Event:Connect whenever this event occurs, call callback
        @param self the event
        @param fCallback the callback function to be called with event data
        @returns 1 (table with method Disconnect to disconnect from the event)
        @part-of eventify
      ]]
      Connect = function(self, fCallback)
        expect(1, self, "table")
        expect(2, fCallback, "function")

        if not tConnections[sEvent] then
          tConnections[sEvent] = {}
        end
        local i = #tConnections[sEvent] + 1
        tConnections[sEvent][i] = fCallback

        return {
          --[[
            @function connection:Disconnect disconnect the callback from being called
            @part-of Event:Connect
          ]]
          Disconnect = function()
            for i = 1, #tConnections[sEvent] do
              if tConnections[sEvent][i] == fCallback then
                table.remove(tConnections[sEvent], i)
                break
              end
            end
          end
        }
      end
    }
end

return eventify
