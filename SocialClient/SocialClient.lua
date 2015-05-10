local programDir = fs.getDir(shell.getRunningProgram()) .. "/"

local utils = dofile(programDir .. "utils.lua")
local SocialNet = dofile(programDir .. "SocialNet.lua")

-- add the SocialNet API to the global table for use in other files
_G.SocialNet = SocialNet

utils.loadAPI(programDir .. "Bedrock.lua", "Bedrock")

Bedrock.BasePath = programDir
Bedrock.ProgramPath = shell.getRunningProgram()

local program = Bedrock:Initialise()

-- Apply Bedrock hacks
utils.Bedrock.SetProgram(program)
program.Drawing = Drawing
utils.Bedrock.BypassBedrockSlowDrawing()
utils.Bedrock.OverrideBedrockButtonDefaultClickDetection()

SC.SetProgram(program)
Init.SetProgram(program)

Button.ActiveBackgroundColour = colors.lightGray
Button.ActiveTextColour = colors.white

function MenuView.OnContentLoad (menuView, contentView, name)
  if Init.OnView[name] then
    Init.OnView[name](menuView, contentView)
  end
end

function MenuView.OnSwitch (menuView, contentView)
  if Init.OnSwitch[contentView.Name] then
    Init.OnSwitch[contentView.Name](menuView, contentView)
  end
end

function program.OnViewLoad (name)
  if Init.OnView[name] then
    Init.OnView[name](program.View)
  end
end

local oldTerm = term.current()
local ok, err = pcall(program.Run, program, function()
  Debug.ClearLog()

  program:RegisterEvent("http_success", function (self, ...)
    SocialNet.EventHandler(...)
  end)
  program:RegisterEvent("http_failure", function (self, ...)
    SocialNet.EventHandler(...)
  end)
end)

Account.CleanUp()
_G.Account = nil

term.redirect(oldTerm)
utils.clear()

if not ok then
  print("An error has occured during the program's execution:")
  printError(err)
end