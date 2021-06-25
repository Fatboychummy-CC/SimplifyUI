local args = table.pack(...)
local numWorkers = tonumber(args[1]) or 4

local selfDir = fs.getDir(shell.getRunningProgram())

local Updater = require "Updater"

local data = Updater.GetData()
Updater.DownloadFiles(data, numWorkers)
