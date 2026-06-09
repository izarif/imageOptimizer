local utf8 = require("lua-utf8")
local lfs = require("lfs")
local cjson = require("cjson")
local iz = require("iz")
local izn = require("izn")

function strSplit(str, seps)
  seps = seps or " "

  local strLen = utf8.len(str)
  local tokenTable = {}
  local result = {}

  for idx = 1, sLen do
    local chr = utf8.sub(str, idx, idx)

    if string.find(seps, chr, 1, true) then
      local token = table.concat(tokenTable)

      table.insert(result, token)

      tokenTable = {}
    else
      table.insert(tokenTable, chr)
    end
  end

  local token = table.join(tokenTable, "")

  table.insert(result, token)

  return result
end

function strRemovePrefix(str, prefix)
  local prefixLen = utf8.len(prefix)
  local result = str

  if utf8.sub(str, 1, prefixLen) == prefix then
    result = utf8.sub(str, prefixLen + 1)
  end

  return result
end

function tableContains(tbl, needle)
  for _, v in ipairs(tbl) do
    if v == needle then
      return true
    end
  end

  return false
end

function getFileDirPath(path)
  local dirPath = utf8.match(path, "(.*[/\\])")

  return dirPath
end

function getFileExt(path)
  local ext = utf8.match(path, "^.+%.(.+)$")
  ext = utf8.lower(ext)

  return ext
end

function makeDir(path)
  if iz.fileExists(path) then
    return nil
  end

  local sep = string.sub(package.config, 1, 1)
  local curPath = ""

  for pathPart in utf8.gmatch(path, "([^/\\]+)") do
    if curPath == "" then
      curPath = pathPart
    else
      curPath = curPath .. sep .. pathPart
    end

    if iz.fileExists(curPath) then
      lfs.mkdir(curPath)
    end
  end
end

function getUserDirPath()
  local userDirPath = os.getenv("HOME")

  if not userDirPath then
    userDirPath = os.getenv("USERPROFILE")
  end

  return userDirPath
end

function normalizePath(path)
  local sep = string.sub(package.config, 1, 1)
  local normPath = string.gsub(path, "[/\\]+", sep)
  normPath = string.gsub(normPath, "[/\\]$", "")

  return normPath
end

function isImgPath(path)
  local imgExts = {
    "png",
    "jpg",
    "jpeg",
    "gif",
  }

  local fileExt = getFileExt(path)
  local result = tableContains(imgExts, fileExt)

  return result
end

local mainChannel = love.thread.getChannel("main")
local workerChannel = love.thread.getChannel("worker")

local isCanceled = false
local userDirPath = getUserDirPath()
local cfg = iz.readCfg()
local reportFile = io.open("report.txt", "w")
local data = cjson.decode(...)
local langCode = data["langCode"]
iz.langTable = iz.readLangTable(langCode)
local inFilePaths = data["filePaths"]

for idx, inFilePath in ipairs(inFilePaths) do
  local mainThreadMsg = {}
  local encodedMainThreadMsg = mainChannel:pop()

  if encodedMainThreadMsg then
    mainThreadMsg = cjson.decode(encodedMainThreadMsg)
  end

  if mainThreadMsg[1] == "cancel" then
    isCanceled = true
    break
  end

  local report = {}
  report["inPath"] = inFilePath
  report["status"] = "ok"

  if not iz.fileExists(inFilePath) then
    report["status"] = "fileNotExist"
  elseif not isImgPath(inFilePath) then
    report["status"] = "unknownFileTypeErr"
  end

  local outFilePath = nil

  if report["status"] == "ok" then
    outFilePath = strRemovePrefix(inFilePath, userDirPath)
    outFilePath = utf8.gsub(outFilePath, "^[a-zA-Z]:", "") -- remove drive letter
    outFilePath = "optimized" .. outFilePath

    if iz.fileExists(outFilePath) then
      report["status"] = "fileAlreadyOptimizedErr"
    end
  end

  if report["status"] == "ok" then
    local outFileDirPath = getFileDirPath(outFilePath)

    makeDir(outFileDirPath)

    local cmd = nil
    local inFileExt = getFileExt(inFilePath)
    local sep = string.sub(package.config, 1, 1)
    local quotedInFilePath = string.format('"%s"', inFilePath)
    local quotedOutFilePath = string.format('"%s"', outFilePath)

    if inFileExt == "png" then
      cmd = string.format(
        ".%sbinaries%s" .. cfg["cmds"][1],
        sep,
        sep,
        quotedOutFilePath,
        quotedInFilePath
      )
    elseif inFileExt == "jpg" or inFileExt == "jpeg" then
      cmd = string.format(
        ".%sbinaries%s" .. cfg["cmds"][2],
        sep,
        sep,
        quotedOutFilePath,
        quotedInFilePath
      )
    elseif inFileExt == "gif" then
      cmd = string.format(
        ".%sbinaries%s" .. cfg["cmds"][3],
        sep,
        sep,
        quotedOutFilePath,
        quotedInFilePath
      )
    end

    izn.execCmd(cmd)

    if not iz.fileExists(outFilePath) then
      report["status"] = "unknownErr"
    end

    if report["status"] == "ok" then
      local inFileSize = lfs.attributes(inFilePath, "size")
      local outFileSize = lfs.attributes(outFilePath, "size")
      local sizeDiff = inFileSize - outFileSize
      local sizeDiffPerc = (sizeDiff / inFileSize) * 100

      report["outPath"] = outFilePath
      report["sizeDiff"] = sizeDiff
      report["sizeDiffPerc"] = sizeDiffPerc
    end
  end

  local status = report["status"]
  local statusMsg = nil

  if status == "ok" then
    local sizeDiff = report["sizeDiff"]
    local sizeDifPerc = report["sizeDiffPerc"]
    statusMsg =
      string.format(iz.translateStr("fileOptimized"), sizeDiff, sizeDifPerc)
  elseif status == "fileNotExist" then
    statusMsg = iz.translateStr("fileNotExist")
  elseif status == "unknownFileTypeErr" then
    statusMsg = iz.translateStr("unknownFileTypeErr")
  elseif status == "fileAlreadyOptimizedErr" then
    statusMsg = iz.translateStr("fileAlreadyOptimizedErr")
  elseif status == "unknownErr" then
    statusMsg = iz.translateStr("unknownErr")
  end

  reportFile:write(report["inPath"] .. "\n")
  reportFile:write(statusMsg .. "\n\n")

  local workerThreadMsg = { "progress", idx }
  local encodedWorkerThreadMsg = cjson.encode(workerThreadMsg)

  workerChannel:push(encodedWorkerThreadMsg)
end

reportFile.close()

local workerThreadMsg = nil

if not isCanceled then
  workerThreadMsg = { "completed" }
else
  workerThreadMsg = { "canceled" }
end

local encodedWorkerThreadMsg = cjson.encode(workerThreadMsg)

workerChannel:push(encodedWorkerThreadMsg)
