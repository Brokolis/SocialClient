Inherit = 'View'
ChildOffset = false

ScrollBarColour = nil
ScrollBarBackgroundColour = nil

ScrollBarName = "BetterScrollViewBetterScrollBar"

OnLoad = function (self)
  self.ChildOffset = {
    X = 0,
    Y = 0
  }

  self:UpdateScroll()
end

OnUpdate = function (self)
  self:UpdateScroll()
end

OnClick = function (self, event, b, x, y)
  self:UpdateScroll()
end

OnScroll = function (self, event, b, x, y)
  local scrollBar = self:GetObject(self.ScrollBarName)

  if scrollBar then
    scrollBar:OnScroll(event, b, x, y)
  end

  self:UpdateScroll()
end

function CalculateContentHeight (self)
  local height = 0

  for i, child in ipairs(self.Children) do
    height = math.max(child.Y + child.Height - 1, height)
  end

  return height
end

function UpdateScroll (self)
  local contentHeight = self:CalculateContentHeight()
  
  if contentHeight > self.Height then
    local scrollBar = self:GetObject(self.ScrollBarName)

    if not scrollBar then
      scrollBar = self:AddObject({
        Type = "BetterScrollBar",
        Name = self.ScrollBarName,
        X = self.Width,
        Y = 1,
        Z = 999,
        Width = 1,
        Height = self.Height,
        ScrollHeight = contentHeight,
        BarColour = self.ScrollBarColour,
        BackgroundColour = self.ScrollBarBackgroundColour,
        Fixed = true
      })

      scrollBar.OnChange = function (scrollBar, scroll)
        self.ChildOffset.Y = -scroll
      end
    end

    scrollBar.ScrollHeight = contentHeight
    scrollBar.Height = self.Height
  else
    self:RemoveObject(self.ScrollBarName)

    if self.ChildOffset then
      self.ChildOffset.Y = 0
    end
  end
end