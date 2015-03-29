local utils = {}

utils.orgTerm = term.current()

utils.loadAPI = function (path, name)
  if name ~= nil then
    if os.loadAPI(path) then
      local oldName = fs.getName(path)

      _G[name] = _G[oldName]
      _G[oldName] = nil

      return true
    end
  end

  return false
end

utils.clear = function (tc, bc, x, y)
  utils.orgTerm.setTextColor(tc or colors.white)
  utils.orgTerm.setBackgroundColor(bc or colors.black)
  utils.orgTerm.clear()
  utils.orgTerm.setCursorPos(x or 1, y or 1)
end

local program
utils.Bedrock = {}

utils.Bedrock.SetProgram = function (p)
  program = p
end

utils.Bedrock.BypassBedrockSlowDrawing = function ()
  local Drawing = program.Drawing
  utils.Bedrock.oldDrawBuffer = Drawing.DrawBuffer

  Drawing.DrawBuffer = function (self)
    if Drawing.TryRestore and Drawing.Restore then
      Drawing.Restore()
    end

    local w, h = term.getSize()
    local termCommands = {}
    local lastbc, lasttc

    local function addCommand (command, ...)
      local arg = {...}
      if command == "setTextColor" and arg[1] ~= lasttc then
        lasttc = ...
        termCommands[#termCommands + 1] = {
          command = term[command],
          ...
        }
      elseif command == "setBackgroundColor" and arg[1] ~= lastbc then
        lastbc = ...
        termCommands[#termCommands + 1] = {
          command = term[command],
          ...
        }
      else
        termCommands[#termCommands + 1] = {
          command = term[command],
          ...
        }
      end
    end

    local function append (c)
      termCommands[#termCommands][1] = termCommands[#termCommands][1] .. c
    end

    local buffer = Drawing.Buffer
    local backBuffer = Drawing.BackBuffer

    local last
    for y = 1, h do
      last = nil
      local row = buffer[y]
      if row then
        for x = 1, w do
          local pixel = row[x]
          if pixel then
            local shouldDraw = true
            if Drawing.BackBuffer[y] and Drawing.BackBuffer[y][x] and #Drawing.BackBuffer[y][x] >= 3 then
              local pixel2 = Drawing.BackBuffer[y][x]
              if pixel[1] == pixel2[1] and pixel[2] == pixel2[2] and pixel[3] == pixel2[3] then
                shouldDraw = false
              end
            end

            if shouldDraw then
              if last then
                if (pixel[2] == last[2] or pixel[1] == " ") and pixel[3] == last[3] then
                  append(pixel[1], x, y)
                else
                  addCommand("setTextColor", pixel[2])
                  addCommand("setBackgroundColor", pixel[3])
                  addCommand("write", pixel[1])
                end
              else
                addCommand("setCursorPos", x, y)
                addCommand("setTextColor", pixel[2])
                addCommand("setBackgroundColor", pixel[3])
                addCommand("write", pixel[1])
              end

              last = pixel
            else
              last = nil
            end
          end
        end
      end
    end

    for i = 1, #termCommands do
      termCommands[i].command(unpack(termCommands[i]))
    end

    Drawing.BackBuffer = Drawing.Buffer
    Drawing.Buffer = {}
  end
end

utils.Bedrock.RestoreOldDrawing = function ()
  if utils.Bedrock.oldDrawBuffer then
    program.Drawing.DrawBuffer = utils.Bedrock.oldDrawBuffer
    utils.Bedrock.oldDrawBuffer = nil
  end
end

utils.Bedrock.OverrideBedrockButtonDefaultClickDetection = function ()
  utils.Bedrock.oldButtonClick = Button.Click

  Button.Click = function (self, event, side, x, y)
    if self.Visible and not self.IgnoreClick and self.Enabled and event ~= 'mouse_scroll' then
      if self.OnClick then
        if self.Momentary then
          self.Toggle = true
          self.Bedrock:StartTimer(function()self.Toggle = false end,0.25)
        elseif self.Toggle ~= nil then
          self.Toggle = not self.Toggle
        end

        if event ~= "mouse_drag" then
          self:OnClick(event, side, x, y, self.Toggle)
        end
      else
        self.Toggle = not self.Toggle
      end
      return true
    else
      return false
    end
  end
end

return utils