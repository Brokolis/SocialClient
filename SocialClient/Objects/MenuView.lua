Inherit = "View"

Menu = nil
Header = nil
Content = nil

ShowMenu = false
MenuAnimationDuration = 1
MenuWidth = 15
HeaderText = "Header"

Headers = nil
ContentViews = nil
MenuItems = nil

ActiveContent = nil

OnInitialise = function (self)
  local header = {
    Type = "View",
    Name = "HeaderView",
    X = 1,
    Y = 1,
    Width = "100%",
    Height = 3,
    BackgroundColour = colors.gray,
    Children = {
      {
        Type = "Button",
        Name = "MenuButton",
        X = 2,
        Y = 2,
        Width = 3,
        BackgroundColour = "lightGray",
        TextColour = "gray",
        Text = " = "
      },
      {
        Type = "Label",
        Name = "HeaderLabel",
        X = 7,
        Y = 2,
        Width = "100%,-10",
        Height = 2,
        TextColour = "white",
        Text = self.HeaderText or "Header"
      },
      {
        X = "100%,-4",
        Y = 2,
        Width = 3,
        Name = "ExitButton",
        Type = "Button",
        Text = " x ",
        BackgroundColour = "lightGray",
        TextColour = "gray"
      }
    }
  }

  local content = {
    Type = "View",
    Name = "ContentView",
    X = 1,
    Y = 4,
    Width = "100%",
    Height = "100%,-3",
    BackgroundColour = "green"
  }

  local menu = {
    Type = "View",
    Name = "MenuView",
    X = 1,
    Y = 1,
    Width = self.MenuWidth,
    Height = "100%",
    BackgroundColour = "gray",
  }

  self.Header = self.Bedrock:ObjectFromFile(header, self)
  self.Content = self.Bedrock:ObjectFromFile(content, self)
  self.Menu = self.Bedrock:ObjectFromFile(menu, self)

  self.Headers = self.Headers or {}

  if type(self.ContentViews) == "table" then
    for i, contentView in ipairs(self.ContentViews) do
      self.ContentViews[i] = nil
      self:LoadContent(contentView)
    end
  end

  if self.ActiveContent then
    self:SwitchContent(self.ActiveContent)
  end

  if type(self.MenuItems) == "table" then
    for i, item in ipairs(self.MenuItems) do
      local newItem = {
        X = 2,
        Y = i * 2,
        Width = "100%,-2",
        Height = 1,
        BackgroundColour = colors.transparent,
        TextColour = colors.lightGray,
        Colour = colors.lightGray,
        Align = "Left"
      }

      for k, v in pairs(item) do
        newItem[k] = v
      end

      self.Menu:AddObject(newItem)

      if item.Switch and newItem.Name then
        self.Menu:GetObject(newItem.Name).OnClick = function (_, event, b, x, y)
          self:SwitchContent(item.Switch, item.SwitchHeader)
        end
      end
    end
  end

  self.Header:GetObject("MenuButton").OnClick = function (_, event, b, x, y)
    self:ToggleMenu()
  end

  if self.ShowMenu then
    self.ShowMenu = not self.ShowMenu
    self:ToggleMenu()
  end
end

OnDraw = function (self)
  self.Menu:Draw()
  self.Header:Draw()
  self.Content:Draw()
end

OnClick = function (self, event, b, x, y)
  if self.ShowMenu then
    self:DoClick(self.Menu, event, b, x, y)

    if self:CheckClick(self.Content, x, y) then
      self:ToggleMenu()
    end
  else
    self:DoClick(self.Content, event, b, x, y)
  end

  self:DoClick(self.Header, event, b, x, y)
end

OnDrag = OnClick
OnScroll = OnClick

function ToggleMenu (self, t)
  if t == self.ShowMenu then
    return
  end

  self.ShowMenu = not self.ShowMenu

  if self.ShowMenu then
    self.Header:AnimateValue("X", self.Header.X, self.MenuWidth + 1, self.MenuAnimationDuration, function ()
      self.Header:GetObject("MenuButton").Text = "<=="
    end)
    self.Content:AnimateValue("X", self.Content.X, self.MenuWidth + 1, self.MenuAnimationDuration)

    self.Content.IgnoreClick = true
  else
    self.Header:AnimateValue("X", self.Header.X, 1, self.MenuAnimationDuration, function ()
      self.Header:GetObject("MenuButton").Text = " = "
    end)
    self.Content:AnimateValue("X", self.Content.X, 1, self.MenuAnimationDuration, function ()
      self.Content.IgnoreClick = false
    end)
  end
end

function SwitchContent (self, name, header)
  header = header or self.Headers[name]

  for i, contentView in ipairs(self.ContentViews) do
    if contentView.Name == name then
      self.Content:RemoveAllObjects()
      self.Content.Children = {contentView}

      self.ActiveContent = name

      if header then
        self:SetHeader(header)
      end

      if self.OnSwitch then
        self:OnSwitch(contentView)
      end

      self:ToggleMenu(false)

      return true
    end
  end

  return false
end

function LoadContent (self, contentView)
  local name
  if type(contentView) == "string" then
    name = contentView

    local file = fs.open(self.Bedrock.ViewPath .. contentView .. ".view", "r")

    if not file then
      return false
    end

    contentView = textutils.unserialize(file.readAll())

    file.close()

    if type(contentView) == "string" then
      return false
    end
  end

  local newContentView = {
    X = 1,
    Y = 1,
    Width = "100%",
    Height = "100%",
    Z = 1
  }

  for k, v in pairs(contentView) do
    newContentView[k] = v
  end

  newContentView = self.Bedrock:ObjectFromFile(newContentView, self.Content)
  self.ContentViews[#self.ContentViews + 1] = newContentView

  if self.OnContentLoad then
    self:OnContentLoad(newContentView, name or newContentView.Name)
  end

  return true
end

function SetHeader (self, header)
  self.HeaderText = header
  self.Header:GetObject("HeaderLabel").Text = header
end