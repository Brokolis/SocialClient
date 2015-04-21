Inherit = "View"

TextColour = colors.lightGray
BackgroundColour = colors.gray

ListTextColour = colors.gray
ListBackgroundColour = colors.lightGray

PlaceHolder = "..."

Height = 3
AllowNils = true

Options = nil
SelectedOption = nil

_IsOpen = false

OnInitialise = function (self)
  if type(self.Options) ~= "table" then
    self.Options = {}
  end
end

OnDraw = function (self, x, y)
  Drawing.DrawBlankArea(x, y, self.Width, 1, self.BackgroundColour)

  local strWidth = self.Width - 3

  Drawing.DrawCharacters(x + self.Width - 1, y, "v", self.BackgroundColour, self.TextColour)

  if self.AllowNils then
    Drawing.DrawCharacters(x + self.Width - 3, y, "x", colors.red, colors.transparent)

    strWidth = strWidth - 2
  end

  local str = (self.SelectedOption and self.Options[self.SelectedOption] or self.PlaceHolder):sub(1, strWidth)

  Drawing.DrawCharacters(x + 1, y, str, self.TextColour, colors.transparent)
end

OnClick = function (self, event, b, x, y)
  if not self._IsOpen then
    if self.AllowNils and x == self.Width - 2 then
      self.SelectedOption = nil
    else
      self:ToggleOpen(true)
    end
  end
end

function ToggleOpen (self, open)
  if self._IsOpen == open then
    return
  end

  if self._IsOpen then
    self:RemoveObject("ListView")

    self._IsOpen = false
  else
    local listScrollView = self:AddObject({
      Type = "BetterScrollView",
      Name = "ListView",
      X = 1,
      Y = 1,
      Width = self.Width,
      Height = self.Height,
      BackgroundColour = self.ListBackgroundColour
    })

    local offset = 1
    for i, option in ipairs(self.Options) do
      listScrollView:AddObject({
        Type = "Button",
        Name = "OptionButton_" .. i,
        X = 1,
        Y = offset,
        Width = self.Width,
        TextColour = self.ListTextColour,
        BackgroundColour = self.ListBackgroundColour,
        Align = "Left",
        Text = option
      }).OnClick = function (button, event, b, x, y)
        local selected = tonumber(button.Name:match("OptionButton_(%d+)"))

        if selected then
          self.SelectedOption = selected
        end

        self:ToggleOpen(false)
      end

      offset = offset + 1
    end

    listScrollView:UpdateScroll()

    self._IsOpen = true
  end
end