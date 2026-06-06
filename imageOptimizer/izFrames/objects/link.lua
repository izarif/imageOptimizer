return function(loveframes)
---------- module start ----------

local newobject = loveframes.NewObject("link", "loveframes_object_link", true)

function newobject:initialize()
  self.type = "link"
  self.text = "example.com"
  self.font = loveframes.basicfont
  self.width = 200
  self.height = 25
  self.down = false
  self.enabled = true
  self.url = "https://example.com/"
  self.OnHover = nil
  self.OnClick = nil

  self:SetDrawFunc()
end

function newobject:update(dt)
  local state = loveframes.state
  local selfstate = self.state

  if state ~= selfstate then
    return
  end

  local visible = self.visible
  local alwaysupdate = self.alwaysupdate

  if not visible then
    if not alwaysupdate then
      return
    end
  end

  self:CheckHover()

  local hover = self.hover
  local parent = self.parent
  local base = loveframes.base
  local update = self.Update

  if not hover then
    self.down = false

    if downobject == self then
      self.hover = true
    end
  else
    if downobject == self then
      self.down = true
    end
end

  -- move to parent if there is a parent
  if parent ~= base and parent.type ~= "list" then
    self.x = self.parent.x + self.staticx
    self.y = self.parent.y + self.staticy
  end

  if update then
    update(self, dt)
  end
end

function newobject:mousepressed(x, y, button)
  local state = loveframes.state
  local selfstate = self.state

  if state ~= selfstate then
    return
  end

  local visible = self.visible

  if not visible then
    return
  end

  local hover = self.hover

  if hover then

  local baseparent = self:GetBaseParent()
    if baseparent and baseparent.type == "frame" then
      baseparent:MakeTop()
    end

	if button == 1 then
      self.down = true
      loveframes.downobject = self
    end
  end

  self.pressed_button = button
end

function newobject:mousereleased(x, y, button)
  local state = loveframes.state
  local selfstate = self.state

  if state ~= selfstate then
    return
  end

  local visible = self.visible

  if not visible then
    return
  end

  local hover = self.hover
  local down = self.down
  local enabled = self.enabled
  local onclick = self.OnClick

  if hover and down and enabled and self.pressed_button == button then
    if onclick then
      onclick(self, x, y)
    end

    self.down = false
  end
end



function newobject:SetEnabled(bool)
  self.enabled = bool

  return self
end

function newobject:GetDown()
	return self.down
end

function newobject:GetEnabled()
	return self.enabled
end

function newobject:SetFont(font)
  self.font = font

  return self
end

function newobject:GetFont(font)
  return self.font
end

function newobject:SetText(text)
  self.text = text

  return self
end

function newobject:GetText()
  return self.text
end

function newobject:SetURL(url)
  self.url = url

  return self
end

function newobject:GetURL()
  return self.url
end

function newobject:AutoSize()
  self.width = self.font:getWidth(self.text)
  self.height = self.font:getHeight()

  return self
end

---------- module end ----------
end
