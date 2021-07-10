--- Registers with an Instance's Actor to various events.

-- Create a new ScriptSignal
local function new(selfObject, signalName)
  local obj = {} --- @type ScriptSignal
  local i = 0

  -- Connect to a signal
  function obj:Connect(func)
    i = i + 1
    local registrationName = string.format("ScriptSignal_%s%d", signalName, i)

    -- Register with the actor a function
    selfObject:GetActor():Register(
      signalName,
      registrationName,
      func
    )

    -- Return a ScriptConnection
    return {
      Connected = true, -- connections start off connected.
      Disconnect = function()
        -- deregister from actor when disconnecting.
        selfObject:GetActor():DeRegister(signalName, registrationName)
        Connected = false
      end
    } --- @type ScriptConnection
  end

  --- Waits for a ScriptSignal event  to occur.
  function obj:Wait()
    i = i + 1
    local registrationName = string.format("ScriptSignal_%s%d", signalName, i)
    local args

    -- Register a temporary function
    selfObject:GetActor():Register(
      signalName,
      registrationName,
      function(...)
        args = table.pack(...)
        os.queueEvent(registrationName)
      end
    )

    -- wait for event to occur
    os.pullEvent(registrationName)

    -- remove the temporary connection
    selfObject:GetActor():DeRegister(signalName, registrationName)

    -- return the information received.
    return table.unpack(args, 1, args.n)
  end
end

return new
