local iz = {}

local lfs = require("lfs")
local cjson = require("cjson")

function iz.readCfg()
  local cfgFile = io.open("config.json")
  local encodedCfg = cfgFile:read("*a")

  cfgFile:close()

  local cfg = cjson.decode(encodedCfg)

  return cfg
end

function iz.writeCfg(cfg)
  local cfgFile = io.open("config.json", "w")
  local encodedCfg = cjson.encode(cfg)

  cfgFile.write(encodedCfg)
  cfgFile:close()
end

iz.langTable = nil

function iz.readLangTable(langCode)
  local langFilePath = string.format("languages/%s.json", langCode)
  local langFile = io.open(langFilePath)
  local encodedLangTable = langFile:read("*a")

  langFile:close()

  local langTable = cjson.decode(encodedLangTable)

  return langTable
end

function iz.translateStr(s)
  local result = s

  if iz.langTable and iz.langTable[s] then
    result = iz.langTable[s]
  end

  return result
end

function iz.fileExists(path)
  local mode = lfs.attributes(path, "mode")

  if mode then
    return true
  end

  return false
end

iz.osName = nil

function iz.getOsName()
  if iz.osName then
    return iz.osName
  end

  local filePath = "C:/Windows/System32/winver.exe"

  if iz.fileExists(filePath) then
    iz.osName = "windows"

    return iz.osName
  end

  filePath = "/usr/bin/sw_vers"

  if iz.fileExists(filePath) then
    iz.osName = "macos"

    return iz.osName
  end

  filePath = "/etc/freebsd-version"

  if iz.fileExists(filePath) then
    iz.osName = "freebsd"

    return iz.osName
  end

  filePath = "/system/build.prop"

  if iz.fileExists(filePath) then
    iz.osName = "android"

    return iz.osName
  end

  iz.osName = "unix"

  return iz.osName
end

return iz
