local _, selfDir = ...
selfDir = fs.getDir(selfDir)

print("Downloader system running in directory", selfDir)

package.path = string.format(
  "%s;/%s/?.lua;/%s/?/init.lua",
  package.path,
  selfDir, selfDir
)
local downloadDataFile = "DownloadData"

local function DownloadFile(remoteLocation)
  local handle, err = http.get(remoteLocation)
  if handle then
    local data = handle.readAll()
    handle.close()
    return true, data
  end
  return false, err
end

local function WriteFile(fileLocation, data)
  local handle, err = io.open(fileLocation, 'w')
  if handle then
    handle:write(data):close()
    return true
  end

  return false, err
end

local function GetFiles()
  local handle, err = io.open(fs.combine(selfDir, downloadDataFile), 'r')
  if handle then
    local data = handle:read("*a")
    handle:close()

    return textutils.serialize(data)
  end
  error(string.format("Failed to open file '%s': %s", fs.combine(selfDir, downloadDataFile), err))
end

local function DrawWorker(worker)
  term.setCursorPos(1, worker.positionY)
  term.clearLine()
  term.write("Worker " .. worker.id .. ": " .. worker.message)
end

local function Progress(c, m, len)
  local frac = c / m
  local lengthFilled = math.floor(frac * len + 0.5)

  return string.rep('\143', lengthFilled)
end

local function DownloadFiles(downloadData)
  local function Work(worker)
    os.pullEvent("download_start")
    --for i, file in ipairs(worker.files) do
    while true do
      os.sleep(math.random(0, 500) / 1000) -- temporary
      local val = math.random(1, 1000)
      worker.message = "Fake Downloading https://dl.dl/" ..  val .. ".lua"
      worker.current = worker.current + 0.5
      worker.hasChanged = true
      os.sleep(math.random(0, 2000) / 1000)
      worker.message = "Fake Writing File /directory/" .. val .. ".lua"
      worker.current = worker.current + 0.5
      worker.hasChanged = true
      if worker.current >= worker.total then
        worker.message = "Idle."
        worker.hasChanged = true
        return
      end
    end
  end

  local workers = {}
  local workerCoroutines = {}
  for i = 1, 6 do print() end
  local x, y = term.getCursorPos()
  for i = 1, 4 do
    workers[i] = {
      message = "Idle.",
      total = 5,
      current = 0,
      positionY = y - 6 + i,
      id = i,
      hasChanged = true
    }
    workerCoroutines[i] = function()
      Work(workers[i])
    end
  end

  local allDone = false
  local drawOrder = {
    "|", "/", "-", "\\"
  }
  local drawIndex = 0
  --term.clear()
  parallel.waitForAll(
    function()
      for i = 1, #workers do DrawWorker(workers[i]) end

      os.sleep(1)
      os.queueEvent("download_start")
      while true do
        os.queueEvent("checkpoint")
        os.pullEvent("checkpoint")
        allDone = true
        --term.clear()
        local count, total = 0, 0
        for i = 1, #workers do
          if workers[i].hasChanged then
            DrawWorker(workers[i])
            workers[i].hasChanged = false
          end
          count = count + workers[i].current
          total = total + workers[i].total
          if workers[i].current < workers[i].total then
            allDone = false
          end
        end

        term.setCursorPos(1, y)
        term.write(string.format("[%s] Downloading files... [%-20s]", drawOrder[drawIndex + 1], Progress(count, total, 20)))


        if allDone then
          for i = 1, #workers do
            workers[i].message = "Stopped."
            DrawWorker(workers[i])
          end
          return
        end
      end
    end,
    function()
      while true do
        os.sleep(0.25)
        drawIndex = (drawIndex + 1) % #drawOrder

        if allDone then return end
      end
    end,
    table.unpack(workerCoroutines)
  )

  term.setCursorPos(1, y) print()
  print("Done. Downloaded files to /directory/*")
end

local function main()
  local downloadData = GetFiles()

  DownloadFiles(downloadData)
end

main()
