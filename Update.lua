local args = table.pack(...)
local selfDir = fs.getDir(shell.getRunningProgram())

local Updater = require "Updater"

local data = Updater.GetData()
Updater.DownloadFiles(data, 4)
