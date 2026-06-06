local loveframes = nil
local maxFps = nil
local workerThread = nil
local mainChannel = nil
local workerChannel = nil

local cjson = nil
local izfd = nil
local iz = nil
local izn = nil

local font = nil
local completedSound = nil
local frameW = nil
local frameH = nil
local frameHeaderH = nil
local padding = nil

local langCode = nil
local cfg = nil

local langFrame = nil
local mainFrame = nil
local sureCancelFrame = nil
local canceledFrame = nil
local completedFrame = nil

function killProc(name)
  local osName = iz.getOsName()
  local cmd = string.format("killall -s KILL '%s'", name)

  if osName == "windows" then
    cmd = string.format('taskkill /f /im "%s.exe"', name)
  end

  izn.execCmd(cmd)
end

function getEveryFirstColumnText(obj)
  local result = {}
  local rows = obj["internals"][1]["children"] -- hack

  for _, row in ipairs(rows) do
    local columnText = row["columndata"][1]

    table.insert(result, columnText)
  end

  return result
end

function cancel()
  if workerThread then
    local mainThreadMsg = { "cancel" }
    local encodedMainThreadMsg = cjson.encode(mainThreadMsg)

    workerChannel:push(encodedMainThreadMsg)
    killProc("optipng")
    killProc("jpegtran")
    killProc("gifsicle")
    workerThread:wait()
  end
end

function createMainFrame()
  local frame = {}
  frame.obj = loveframes.Create("frame")
  frame.obj:SetName("imageOptimizer")
  frame.obj:SetSize(frameW, frameH)
  frame.obj:SetDraggable(false)
  frame.obj:ShowCloseButton(false)
  frame.obj:SetVisible(false)

  frame.filesText = loveframes.Create("text", frame.obj)
  frame.filesText:SetFont(font)
  frame.filesText:SetText(iz.translateStr("files"))

  frame.filesColumnList = loveframes.Create("columnlist", frame.obj)
  frame.filesColumnList:SetSize(300, 200)
  frame.filesColumnList:SetMultiselectEnabled(true)
  frame.filesColumnList:AddColumn("") -- add column because otherwise we can't add rows
  frame.filesColumnList:SetColumnHeight(0) -- hide header row

  frame.addButton = loveframes.Create("button", frame.obj)
  frame.addButton:SetFont(font)
  frame.addButton:SetText(iz.translateStr("add"))
  frame.addButton:AutoSize() -- method that is not implemented in loveFrames

  frame.removeButton = loveframes.Create("button", frame.obj)
  frame.removeButton:SetFont(font)
  frame.removeButton:SetText(iz.translateStr("remove"))
  frame.removeButton:AutoSize()

  frame.startButton = loveframes.Create("button", frame.obj)
  frame.startButton:SetFont(font)
  frame.startButton:SetText(iz.translateStr("start"))
  frame.startButton:AutoSize()

  frame.cancelButton = loveframes.Create("button", frame.obj)
  frame.cancelButton:SetFont(font)
  frame.cancelButton:SetText(iz.translateStr("cancel"))
  frame.cancelButton:AutoSize()
  frame.cancelButton:SetEnabled(false)

  frame.progressText = loveframes.Create("text", frame.obj)
  frame.progressText:SetFont(font)
  frame.progressText:SetText(iz.translateStr("progress"))

  frame.progressBar = loveframes.Create("progressbar", frame.obj)
  frame.progressBar:SetWidth(300)
  frame.progressBar:SetMin(0)
  frame.progressBar:SetMax(100)
  frame.progressBar:SetValue(0)

  -- i know that text widget can parse links but i created different widget with less logic
  frame.link = loveframes.Create("link", frame.obj)
  frame.link:SetFont(font)
  frame.link:SetText(iz.translateStr("donate"))
  frame.link:SetURL("https://boosty.to/izarif/donate/")
  frame.link:AutoSize()

  frame.filesText:SetPos(padding, frameHeaderH + padding)
  frame.filesColumnList:SetPos(
    padding,
    frameHeaderH + frame.filesText:GetHeight() + padding * 2
  )
  frame.addButton:SetPos(
    padding,
    frameHeaderH
      + frame.filesText:GetHeight()
      + frame.filesColumnList:GetHeight()
      + padding * 3
  )
  frame.removeButton:SetPos(
    frame.addButton:GetWidth() + padding * 2,
    frameHeaderH
      + frame.filesText:GetHeight()
      + frame.filesColumnList:GetHeight()
      + padding * 3
  )
  frame.startButton:SetPos(
    padding,
    frameHeaderH
      + frame.filesText:GetHeight()
      + frame.filesColumnList:GetHeight()
      + frame.addButton:GetHeight()
      + padding * 4
  )
  frame.cancelButton:SetPos(
    frame.startButton:GetWidth() + padding * 2,
    frameHeaderH
      + frame.filesText:GetHeight()
      + frame.filesColumnList:GetHeight()
      + frame.addButton:GetHeight()
      + padding * 4
  )
  frame.progressText:SetPos(
    padding,
    frameHeaderH
      + frame.filesText:GetHeight()
      + frame.filesColumnList:GetHeight()
      + frame.addButton:GetHeight()
      + frame.startButton:GetHeight()
      + padding * 5
  )
  frame.progressBar:SetPos(
    padding,
    frameHeaderH
      + frame.filesText:GetHeight()
      + frame.filesColumnList:GetHeight()
      + frame.addButton:GetHeight()
      + frame.startButton:GetHeight()
      + frame.progressText:GetHeight()
      + padding * 6
  )
  frame.link:SetPos(
    padding,
    frameHeaderH
      + frame.filesText:GetHeight()
      + frame.filesColumnList:GetHeight()
      + frame.addButton:GetHeight()
      + frame.startButton:GetHeight()
      + frame.progressText:GetHeight()
      + frame.progressBar:GetHeight()
      + padding * 7
  )

  frame.addButton.OnClick = function(obj, x, y)
    local filePaths = izfd.openMany2("png,jpg,jpeg,gif") -- function that is not implemented in nativeFileDialog

    if not filePaths then
      filePaths = {}
    end

    for _, filePath in ipairs(filePaths) do
      frame.filesColumnList:AddRow(filePath)
    end

    --  we dont use SizeColumnToData function to do multiple operations in one loop
    local rows = frame.filesColumnList["internals"][1]["children"]
    local maxRowContentW = 10

    for id, row in ipairs(rows) do
      frame.filesColumnList:SetRowFont(font, id)
      row:AutoSize()

      local rowContentW =
        row:GetFont():getWidth(frame.filesColumnList:GetCellText(id, 1))

      if rowContentW > maxRowContentW then
        maxRowContentW = rowContentW + 8 * 2
      end
    end

    frame.filesColumnList:SetColumnWidth(1, maxRowContentW)
  end

  frame.removeButton.OnClick = function(obj, x, y)
    local selectedRowIds = frame.filesColumnList:GetSelectedRowIDs()

    for _, id in ipairs(selectedRowIds) do
      frame.filesColumnList:RemoveRow(id)
    end
  end

  frame.startButton.OnClick = function(obj, x, y)
    frame.addButton:SetEnabled(false)
    frame.removeButton:SetEnabled(false)
    obj:SetEnabled(false)
    frame.cancelButton:SetEnabled(true)
    frame.progressBar:SetValue(0)

    local filePaths = getEveryFirstColumnText(frame.filesColumnList)
    local filePathsCount = #filePaths

    frame.progressBar:SetMax(filePathsCount)

    local data = {}
    data["langCode"] = langCode
    data["filePaths"] = filePaths

    local encodedData = cjson.encode(data)
    workerThread = love.thread.newThread("worker.lua")
    mainChannel = love.thread.getChannel("main")
    workerChannel = love.thread.getChannel("worker")

    workerThread:start(encodedData)
  end

  frame.cancelButton.OnClick = function(obj, x, y)
    cancel()
  end

  frame.link.OnClick = function(obj, x, y)
    local url = frame.link:GetURL()
    local osName = iz.getOsName()
    local cmd = string.format("xdg-open '%s'", url)

    if osName == "windows" then
      cmd = string.format('start "" "%s"', url)
    elseif osName == "macos" then
      cmd = string.format("open '%s'", url)
    end

    izn.execCmd(cmd)
  end

  return frame
end

function createLangFrame()
  local frame = {}
  frame.obj = loveframes.Create("frame")
  frame.obj:SetName("Language")
  frame.obj:SetSize(frameW, frameH)
  frame.obj:SetDraggable(false)
  frame.obj:ShowCloseButton(false)

  frame.selectText = loveframes.Create("text", frame.obj)
  frame.selectText:SetFont(font)
  frame.selectText:SetText("Select language")

  frame.multiChoice = loveframes.Create("multichoice", frame.obj)

  for _, lang in ipairs(cfg["langs"]) do
    frame.multiChoice:AddChoice(lang["name"])
  end

  frame.multiChoice:SetChoice("English")

  frame.okButton = loveframes.Create("button", frame.obj)
  frame.okButton:SetFont(font)
  frame.okButton:SetText("Ok")
  frame.okButton:AutoSize()

  frame.selectText:SetPos(padding, frameHeaderH + padding)
  frame.multiChoice:SetPos(
    padding,
    frameHeaderH + frame.selectText:GetHeight() + padding * 2
  )
  frame.okButton:SetPos(
    padding,
    frameHeaderH
      + frame.selectText:GetHeight()
      + frame.multiChoice:GetHeight()
      + padding * 3
  )

  frame.okButton.OnClick = function(obj, x, y)
    local selectedLangIdx = frame.multiChoice:GetChoiceIndex()
    langCode = cfg["langs"][selectedLangIdx]["code"]
    iz.langTable = iz.readLangTable(langCode)

    mainFrame = createMainFrame()
    sureCancelFrame = createSureCancelFrame()
    canceledFrame = createCanceledFrame()
    completedFrame = createCompletedFrame()

    langFrame.obj:SetVisible(false)
    mainFrame.obj:SetVisible(true)
  end

  return frame
end

function createSureCancelFrame()
  local frame = {}
  frame.obj = loveframes.Create("frame")
  frame.obj:SetName(iz.translateStr("cancelTitle"))
  frame.obj:SetSize(frameW, frameH)
  frame.obj:SetDraggable(false)
  frame.obj:ShowCloseButton(false)
  frame.obj:SetVisible(false)

  frame.text = loveframes.Create("text", frame.obj)
  frame.text:SetFont(font)
  frame.text:SetText(iz.translateStr("sureCancel"))

  frame.yesButton = loveframes.Create("button", frame.obj)
  frame.yesButton:SetFont(font)
  frame.yesButton:SetText(iz.translateStr("yes"))
  frame.yesButton:AutoSize()

  frame.noButton = loveframes.Create("button", frame.obj)
  frame.noButton:SetFont(font)
  frame.noButton:SetText(iz.translateStr("no"))
  frame.noButton:AutoSize()

  frame.text:SetPos(padding, frameHeaderH + padding)
  frame.yesButton:SetPos(
    padding,
    frameHeaderH + frame.text:GetHeight() + padding * 2
  )
  frame.noButton:SetPos(
    frame.yesButton:GetWidth() + padding * 2,
    frameHeaderH + frame.text:GetHeight() + padding * 2
  )

  frame.noButton.OnClick = function(obj, x, y)
    frame.obj:SetVisible(false)
    mainFrame.obj:SetVisible(true)
  end

  return frame
end

function createCanceledFrame()
  local frame = {}
  frame.obj = loveframes.Create("frame")
  frame.obj:SetName(iz.translateStr("canceledTitle"))
  frame.obj:SetSize(frameW, frameH)
  frame.obj:SetDraggable(false)
  frame.obj:ShowCloseButton(false)
  frame.obj:SetVisible(false)

  frame.text = loveframes.Create("text", frame.obj)
  frame.text:SetFont(font)
  frame.text:SetText(iz.translateStr("processCanceled"))

  frame.okButton = loveframes.Create("button", frame.obj)
  frame.okButton:SetFont(font)
  frame.okButton:SetText(iz.translateStr("ok"))
  frame.okButton:AutoSize()

  frame.text:SetPos(padding, frameHeaderH + padding)
  frame.okButton:SetPos(
    padding,
    frameHeaderH + frame.text:GetHeight() + padding * 2
  )

  frame.okButton.OnClick = function(obj, x, y)
    frame.obj:SetVisible(false)
    mainFrame.obj:SetVisible(true)
  end

  return frame
end

function createCompletedFrame()
  local frame = {}
  frame.obj = loveframes.Create("frame")
  frame.obj:SetName(iz.translateStr("completedTitle"))
  frame.obj:SetSize(frameW, frameH)
  frame.obj:SetDraggable(false)
  frame.obj:ShowCloseButton(false)
  frame.obj:SetVisible(false)

  frame.text = loveframes.Create("text", frame.obj)
  frame.text:SetFont(font)
  frame.text:SetText(iz.translateStr("processCompleted"))

  frame.okButton = loveframes.Create("button", frame.obj)
  frame.okButton:SetFont(font)
  frame.okButton:SetText(iz.translateStr("ok"))
  frame.okButton:AutoSize()

  frame.text:SetPos(padding, frameHeaderH + padding)
  frame.okButton:SetPos(
    padding,
    frameHeaderH + frame.text:GetHeight() + padding * 2
  )

  frame.okButton.OnClick = function(obj, x, y)
    frame.obj:SetVisible(false)
    mainFrame.obj:SetVisible(true)
  end

  return frame
end

function love.load()
  loveframes = require("izFrames")
  cjson = require("cjson")
  izfd = require("izfd")
  iz = require("iz")
  izn = require("izn")

  maxFps = 30
  cfg = iz.readCfg()

  loveframes.SetActiveSkin("green")

  font = love.graphics.newFont("resources/dejaVuSansRegular.ttf", 16)
  completedSound = love.audio.newSource("resources/completed.ogg", "static")
  frameW = 310
  frameH = 405
  frameHeaderH = 25
  padding = 5

  langFrame = createLangFrame()
end

function love.update(dt)
  if dt < 1 / maxFps then
    love.timer.sleep(1 / maxFps - dt)
  end

  loveframes.update(dt)

  local workerMsg = {}

  if workerChannel then
    local encodedWorkerMsg = workerChannel:pop()

    if encodedWorkerMsg then
      workerMsg = cjson.decode(encodedWorkerMsg)
    end
  end

  if workerMsg[1] == "progress" then
    mainFrame.progressBar:SetValue(workerMsg[2])
  elseif workerMsg[1] == "completed" then
    mainFrame.obj:SetVisible(false)
    completedFrame.obj:SetVisible(true)
    completedSound:play()
  elseif workerMsg[1] == "canceled" then
    mainFrame.obj:SetVisible(false)
    canceledFrame.obj:SetVisible(true)
  end

  if workerMsg[1] == "completed" or workerMsg[1] == "canceled" then
    workerThread:wait()
    mainFrame.addButton:SetEnabled(true)
    mainFrame.removeButton:SetEnabled(true)
    mainFrame.startButton:SetEnabled(true)
    mainFrame.cancelButton:SetEnabled(false)
  end
end

function love.draw()
  loveframes.draw()
end

function love.mousepressed(x, y, button)
  loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
  loveframes.mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
  loveframes.wheelmoved(x, y)
end

function love.keypressed(key, isrepeat)
  loveframes.keypressed(key, isrepeat)
end

function love.keyreleased(key)
  loveframes.keyreleased(key)
end

function love.TextInput(text)
  loveframes.TextInput(text)
end

function love.quit()
  cancel()
end
