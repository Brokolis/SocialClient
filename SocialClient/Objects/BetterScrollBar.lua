BarColour = colors.gray
BackgroundColour = colors.lightGray
ScrollHeight = 10

Scroll = 0

ClickY = nil
IsDragging = false

local function round (n)
  return math.floor(n + 0.5)
end

local function clamp (n, min, max)
  return n > max and max or n < min and min or n
end

OnDraw = function (self, x, y)
  local dim = self:GetScrollBarDimesions()

  Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
  Drawing.DrawBlankArea(x, y + dim.Y, self.Width, dim.Height, self.BarColour)
end

OnClick = function (self, event, b, x, y)
  local dim = self:GetScrollBarDimesions()

  if y >= dim.Y and y <= dim.Y + dim.Height then
    self.ClickY = y
    self.IsDragging = true
  end
end

OnDrag = function (self, event, b, x, y)
  if self.IsDragging then
    local diff = y - self.ClickY

    if diff ~= 0 then
      self.ClickY = y

      local dim = self:GetScrollBarDimesions()
      local pixelSize = (self.ScrollHeight - self.Height) / (self.Height - dim.Height)
      local moveAmount = pixelSize * diff

      self:ScrollDown(moveAmount)
    end
  end
end

OnScroll = function (self, event, dir, x, y)
  self.IsDragging = false
  self:ScrollDown(dir)
end

function GetScrollBarDimesions (self)
  local dim = {}

  dim.Height = clamp(round(self.Height * self.Height / self.ScrollHeight), 1, self.Height)
  dim.Y = clamp(round((self.Height - dim.Height) * self.Scroll), 0, self.Height - dim.Height)

  return dim
end

function GetCurrentScroll (self)
  return round((self.ScrollHeight - self.Height) * self.Scroll)
end

function ScrollDown (self, n)
  local moveAmount = n / (self.ScrollHeight - self.Height)
  local lastScroll = self.Scroll

  self.Scroll = clamp(self.Scroll + moveAmount, 0, 1)

  if self.Scroll ~= lastScroll and self.OnChange then
    self:OnChange(self:GetCurrentScroll())
  end
end