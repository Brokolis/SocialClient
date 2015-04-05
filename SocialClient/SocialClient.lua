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

onView["posts_screen"] = function (menuView, contentView)
  contentView:GetObject("ShowPostsButton").OnClick = function (self, event, b, x, y)
    SC.Posts.ShowPosts(contentView, "post")
  end

  contentView:GetObject("ShowTweetsButton").OnClick = function (self, event, b, x, y)
    SC.Posts.ShowPosts(contentView, "tweet")
  end
end

onView["login_screen"] = function (menuView, contentView)
  local loginView = contentView:GetObject("LoginView")
  local logoutView = contentView:GetObject("LogoutView")
  local loggingIn = contentView:GetObject("LoggingIn")

  loginView:GetObject("LoginButton").OnClick = function (self, event, b, x, y)
    local username = loginView:GetObject("UsernameTextBox").Text
    local password = loginView:GetObject("PasswordTextBox").Text

    program:SetActiveObject()
    loggingIn.Visible = true
    loginView.Visible = false

    Account.Login(username, password, function ()
      menuView.Menu:GetObject("LoggedInAs").Text = Account.Username
      loginView:GetObject("UsernameTextBox").Text = ""

      logoutView:GetObject("Username").Text = Account.Username

      loginView.Visible = false
      logoutView.Visible = true
    end, function ()
      program:DisplayAlertWindow("Failed to log in", "The username or password is incorrect.", {"OK"})

      loginView.Visible = true
      logoutView.Visible = false
    end, function ()
      loginView:GetObject("PasswordTextBox").Text = ""

      loggingIn.Visible = false
    end)
  end

  logoutView:GetObject("LogoutButton").OnClick = function (self, event, b, x, y)
    Account.Logout()

    menuView.Menu:GetObject("LoggedInAs").Text = "not logged in"
    logoutView:GetObject("Username").Text = "not logged in"

    loginView.Visible = true
    logoutView.Visible = false
  end
end

local onSwitch = {}

onSwitch["PostsScreen"] = function (menuView, contentView)
  if SC.Posts.CheckLogin(contentView) then
    SC.Posts.ShowPosts(contentView, "post")
  end
end

onSwitch["LoginScreen"] = function (menuView, contentView)
  if Account.IsLoggedIn() then
    contentView:GetObject("LoginView").Visible = false
    contentView:GetObject("LogoutView").Visible = true
  else
    contentView:GetObject("LoginView").Visible = true
    contentView:GetObject("LogoutView").Visible = false
  end
end

function MenuView.OnContentLoad (menuView, contentView, name)
  if onView[name] then
    onView[name](menuView, contentView)
  end
end

function MenuView.OnSwitch (menuView, contentView)
  if onSwitch[contentView.Name] then
    onSwitch[contentView.Name](menuView, contentView)
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