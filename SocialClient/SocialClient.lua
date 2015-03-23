local programDir = fs.getDir(shell.getRunningProgram()) .. "/"

local utils = dofile(programDir .. "utils.lua")
utils.loadAPI(programDir .. "Bedrock.lua", "Bedrock")

Bedrock.BasePath = programDir
Bedrock.ProgramPath = shell.getRunningProgram()

local program = Bedrock:Initialise()
utils.Bedrock.SetProgram(program)
program.Drawing = Drawing
utils.Bedrock.BypassBedrockSlowDrawing()

local onView = {}

onView["main"] = function (view)
  local menuView = view:GetObject("MainMenuView")

  menuView.Header:GetObject("ExitButton").OnClick = function (self, event, b, x, y)
    program:Quit()
  end
end

onView["startup_screen"] = function (menuView, contentView)
  contentView:GetObject("GoToMainButton").OnClick = function (self, event, b, x, y)
    menuView:SwitchContent("MainScreen")
  end
end

MenuView.test = true

function MenuView.OnContentLoad (menuView, contentView, name)
  if onView[name] then
    onView[name](menuView, contentView)
  end
end

function program.OnViewLoad (name)
  if onView[name] then
    onView[name](program.View)
  end
end

function program.OnQuit ()
  utils.clear()
end

program:Run(function()
  
end)