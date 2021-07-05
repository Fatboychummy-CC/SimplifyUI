local args = table.pack(...)
local ok, updater = pcall(require, "Updater")
if not ok then
  ok, updater = pcall(require, "libs/Updater")
end

local function Update()

end

local function Install()
  print("It looks like the updater library is not available on this computer, or is in a non-standard location.")
  print("If you have the updater library installed, type the path to the \"Updater/init.lua\" file, otherwise click the button below.")
end

if ok then
  Update()
else
  Install()
end

--[[
local args = table.pack(...)
local numWorkers = tonumber(args[1])

local selfDir = fs.getDir(shell.getRunningProgram())

local Updater = require "Updater"

local data = Updater.GetData()
Updater.DownloadFiles(data, numWorkers or #data / 4)
]]
