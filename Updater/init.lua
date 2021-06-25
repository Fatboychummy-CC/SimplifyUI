local expect = require "cc.expect".expect

local selfDir = fs.getDir(shell.getRunningProgram())

print("Downloader system running in directory", selfDir)

package.path = string.format(
  "%s;/%s/?.lua;/%s/?/init.lua",
  package.path,
  selfDir, selfDir
)
local downloadDataFile = fs.combine(selfDir, "DownloadData")
local remoteFallBack = "https://raw.githubusercontent.com/Fatboychummy-CC/SimplifyUI/Development/Updater/UpdateData"

local function WriteFile(fileLocation, data)
  local handle, err = io.open(fileLocation, 'w')
  if handle then
    handle:write(data):close()
    return true
  end

  return false, err
end

--- Get the newest available data.
-- @treturn table The most available update data.
local function GetData()
  local data, remoteLocation

  -- Open the downloadData file
  local handle, err = io.open(downloadDataFile, 'r')

  -- if it exists, get the data from it.
  if handle then
    data = handle:read("*a")
    handle:close()

    data = textutils.unserialize(data)

    remoteLocation = data.RemoteLocation .. "/" .. data.RemoteDataLocation
  else
    -- if it doesn't exist, use the fallback
    remoteLocation = remoteFallBack
  end

  -- Grab the file
  local handle2, err = http.get(remoteLocation)
  if handle2 then
    local data2 = handle2.readAll() -- get its data
    handle2.close()
    return textutils.unserialize(data2) -- return the data
  else
    error(string.format("Failed to get %s: %s", remoteLocation, err))
  end
end

local function DrawWorker(worker)
  term.setCursorPos(1, worker.positionY)
  term.clearLine()
  term.write(string.format("Worker %d: ", worker.id))
  if worker.errored then term.setTextColor(colors.red) end
  term.write(worker.message)
  term.setTextColor(colors.white)
end

local function Progress(c, m, len)
  local frac = c / m
  local lengthFilled = math.floor(frac * len + 0.5)

  return string.rep('\143', lengthFilled)
end

--- Download all the files needed.
-- @tparam table downloadData The data from GetData.
-- @tparam number numWorkers The number of workers to use.
local function DownloadFiles(downloadData, numWorkers)
  expect(1, downloadData, "table")
  expect(2, numWorkers, "number", "nil")

  numWorkers = numWorkers or 1
  local downloadQueue = {} -- queue that the workers pull from when ready.
  local workers = {} -- array of workers.
  local workerCoroutines = {} -- array of workers as coroutines (actually functions but whatever).
  local allDone = false -- available to multiple parallel functions to wait for done signal
  local drawOrder = { -- spinny spinny
    "|", "/", "-", "\\"
  }
  local drawIndex = 0 -- spinny spinny order

  local function workerCheckpoint()
    os.queueEvent("worker_update")
    os.pullEvent("worker_update")
  end

  -- Worker function
  -- This is used in parallel to have multiple workers downloading files.
  local function Work(worker)
    -- wait for ready signal.
    os.pullEvent("download_start")

    -- main worker loop
    while true do
      -- Get the next file available for download.
      local current = table.remove(downloadQueue, 1)

      -- If there was none available, This worker is done.
      if not current then
        worker.hasChanged = true
        worker.message = "Stopped."
        worker.stopped = true
        workerCheckpoint()
        return
      end


      -- There was a file available, download it.
      -- Check if there's a remote location
      local remote = current.RemoteLocation
      if not remote then
        remote = downloadData.RemoteLocation .. "/" .. current.FileLocation
      end -- if not, default to file location

      -- set message
      worker.hasChanged = true
      worker.message = string.format("Downloading %s", current.FileLocation)
      workerCheckpoint()

      -- Get the file
      local handle, err = http.get(remote)
      if handle then -- success!
        local data = handle.readAll() -- read the data
        handle.close()

        -- attempt to write 5 times.
        for i = 1, 5 do
          -- change message to writing
          worker.message = string.format("Writing: %s", fs.combine(selfDir, current.FileLocation))
          worker.hasChanged = true
          workerCheckpoint()

          -- Attempt to write the file.
          local ok, err = WriteFile(fs.combine(selfDir, current.FileLocation), data)

          -- If we succeeded, exit this loop.
          if ok then
            worker.message = "Idle."
            worker.hasChanged = true
            workerCheckpoint()
            break
          else
            -- if failed 5 times, error
            if i == 5 then
              error(string.format("Failed to write file '%s' 5 times.", current.FileLocation))
            end
            -- set the message
            worker.message = string.format("Failure: %s", err)
            worker.errored = true
            worker.hasChanged = true
            workerCheckpoint()
            os.sleep(1) -- wait so we can see the error.
          end
        end
      else -- failure
        worker.message = string.format("Failure: %s", err)
        worker.errored = true
        worker.hasChanged = true
        current.failures = (current.failures and current.failures or 0) + 1
        if current.failures >= 5 then
          error(string.format("Failed to download file '%s' 5 times.", current.FileLocation))
        end
        table.insert(downloadQueue, current)
        workerCheckpoint()
        os.sleep(1)
      end
    end
  end

  -- Insert files to downloadQueue
  for i = 1, #downloadData do
    downloadQueue[i] = downloadData[i]
  end
  local totalDownloads = #downloadQueue

  -- kick the terminal down far enough to draw what we need.
  for i = 1, numWorkers + 2 do print() end

  -- get the position the cursor is at. We know the workers are above this, and the status line is this line.
  local x, y = term.getCursorPos()

  -- For each worker, create the worker object and coroutine.
  for i = 1, numWorkers do
    workers[i] = {
      message = "Idle.",
      positionY = y - (numWorkers + 2) + i,
      id = i,
      hasChanged = true,
      errored = false,
      stopped = false
    }
    workerCoroutines[i] = function()
      Work(workers[i])
    end
  end

  -- Run all functions in parallel.
  parallel.waitForAll(
    function()
      for i = 1, #workers do DrawWorker(workers[i]) end

      os.sleep(1)
      os.queueEvent("download_start")
      os.queueEvent("worker_update")
      while true do
        os.pullEvent("worker_update")

        allDone = true

        -- for each worker
        for i = 1, #workers do
          -- draw the worker if it changed
          if workers[i].hasChanged then
            DrawWorker(workers[i])
            workers[i].hasChanged = false
          end

          -- check if any workers are still active.
          if not workers[i].stopped then
            allDone = false
          end
        end

        -- draw the status message.
        term.setCursorPos(1, y)
        term.write(string.format("[%s] Downloading files... [%-20s]", drawOrder[drawIndex + 1], Progress(totalDownloads - #downloadQueue, totalDownloads, 20)))

        -- if all workers are done
        if allDone then
          for i = 1, #workers do
            -- ensure they've been redrawn to "Stopped."
            workers[i].message = "Stopped."
            DrawWorker(workers[i])
          end
          -- then exit.
          return
        end
      end
    end,
    function()
      while true do -- spinny spinny until all done.
        os.sleep(0.25)
        drawIndex = (drawIndex + 1) % #drawOrder
        os.queueEvent("worker_update")

        if allDone then return end
      end
    end,
    table.unpack(workerCoroutines)
  )

  term.setCursorPos(1, y) print()
  print(string.format("Done. Downloaded files to /%s/*", selfDir))
end

--- Do an update, deleting unnecessary files and grabbing new files.
local function DoUpdate()

end

return {
  DoUpdate = DoUpdate,
  DownloadFiles = DownloadFiles,
  GetData = GetData
}
