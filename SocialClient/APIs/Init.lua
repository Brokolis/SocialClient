local program = Bedrock

function SetProgram (p)
  program = p
end

OnView = {}
OnSwitch = {}

OnView["main"] = function (view)
  local menuView = view:GetObject("MainMenuView")

  menuView.Header:GetObject("ExitButton").OnClick = function (self, event, b, x, y)
    program:Quit()
  end
end

OnView["startup_screen"] = function (menuView, contentView)
  contentView:GetObject("GoToMainButton").OnClick = function (self, event, b, x, y)
    menuView:SwitchContent("MainScreen")
  end
end

OnView["posts_screen"] = function (menuView, contentView)
  contentView:GetObject("ShowPostsButton").OnClick = function (self, event, b, x, y)
    SC.Posts.ShowPosts(contentView, menuView, "post")
  end

  contentView:GetObject("ShowTweetsButton").OnClick = function (self, event, b, x, y)
    SC.Posts.ShowPosts(contentView, menuView, "tweet")
  end

  contentView:GetObject("NewPostButton").OnClick = function (self, event, b, x, y)
    if SC.Posts.CheckLogin(contentView) then
      menuView:SwitchContent("NewPostScreen")
    end
  end
end

OnView["new_post_screen"] = function (menuView, contentView)
  contentView:GetObject("CancelButton").OnClick = function (self, event, b, x, y)
    menuView:SwitchContent("PostsScreen")
  end

  contentView:GetObject("PostButton").OnClick = function (self, event, b, x, y)
    SC.Posts.NewPost(contentView, menuView)
  end

  contentView:GetObject("PostTypeDropDownList").OnUpdate = function (self, prop)
    if prop == "SelectedOption" then
      local selected = self.SelectedOption

      if selected == 1 then
        contentView:GetObject("MessageParameters").Y = 4
      elseif selected == 2 then
        contentView:GetObject("MessageParameters").Y = 1
      end
    end
  end
end

OnView["view_post_screen"] = function (menuView, contentView)
  contentView:GetObject("BackButton").OnClick = function (self, event, b, x, y)
    SC.Posts.ReloadPosts = false
    menuView:SwitchContent("PostsScreen")
  end

  contentView:GetObject("DeleteButton").OnClick = function (self, event, b, x, y)
    program:DisplayAlertWindow("Delete the post?", "Are you sure you want to delete this post?", {"No", "Yes"}, function (option)
      if option == "Yes" then
        local postID = contentView:GetObject("PostID").PostID

        local deleting = contentView:GetObject("Deleting")
        local post = contentView:GetObject("Post")

        deleting.Visible = true
        post.Visible = false

        local ok, request = SocialNet.Posts.DeletePost(Account.Username, Account.Password, postID)

        if not ok then
          program:DisplayAlertWindow("Failed to delete post", "An error occured while trying to delete the post:\n" + request, {"OK"})
          return
        end

        request.success = function (url, data, code, rawData)
          if not data.ok then
            program:DisplayAlertWindow("Failed to delete post", "An error occured while trying to delete the post:\n" + data.error, {"OK"})
          end

          SC.Posts.ReloadPosts = true
          menuView:SwitchContent("PostsScreen")
        end

        request.failure = function (url)
          program:DisplayAlertWindow("Failed to delete post", "Could not delete the post.", {"OK"})
        end

        request.done = function (url)
          deleting.Visible = false
          post.Visible = true
        end
      end
    end)
  end
end

OnView["login_screen"] = function (menuView, contentView)
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
      program:DisplayAlertWindow("Failed to log in", "The username or password was incorrect.", {"OK"})

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

OnSwitch["PostsScreen"] = function (menuView, contentView)
  if SC.Posts.CheckLogin(contentView) then
    SC.Posts.ShowPosts(contentView, menuView, "post")
  end
end

OnSwitch["LoginScreen"] = function (menuView, contentView)
  if Account.IsLoggedIn() then
    contentView:GetObject("LoginView").Visible = false
    contentView:GetObject("LogoutView").Visible = true
  else
    contentView:GetObject("LoginView").Visible = true
    contentView:GetObject("LogoutView").Visible = false
  end
end