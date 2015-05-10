local program = Bedrock

function SetProgram (p)
  program = p
end

local function ShowError (msg)
  program:DisplayAlertWindow("An error occurred", msg, {"OK"})
end

Posts = {}

Posts.ReloadPosts = true

Posts.ShowPosts = function (view, menuView, postType)
  if not Posts.CheckLogin(view) or not Posts.ReloadPosts then
    Posts.ReloadPosts = true
    return
  end

  local postsView = view:GetObject("PostsView")
  local loading = view:GetObject("Loading")

  postsView:RemoveAllObjects()

  postsView.Visible = false
  loading.Visible = true

  local ok, request = SocialNet.Posts.GetAllPosts(Account.Username, Account.Password)

  if not ok then
    ShowError(request)
    return
  end

  request.success = function (url, data, code, rawData)
    if not data.ok then
      ShowError(data.error)
      return
    end

    local yOffset = 3

    for i, post in ipairs(data.data) do
      if postType == nil or post.Type == postType then
        local isTweet = post.Type == "tweet"

        local newPost = {
          Type = "View",
          Name = "Post",
          X = 2,
          Y = yOffset,
          Width = "100%,-3",
          Children = {
            {
              Type = "Label",
              Name = "PostHeader",
              X = 1,
              Y = 1,
              Width = "100%",
              Height = 1,
              Text = isTweet and "" or post.Header,
              Visible = not isTweet
            },
            {
              Type = "Label",
              Name = "PostAuthorAndDate",
              X = 1,
              Y = isTweet and 1 or 2,
              Width = "100%",
              Height = 1,
              TextColour = colors.gray,
              Text = "- " .. post.User .. " @ " .. post.DatePosted
            },
            {
              Type = "Label",
              Name = "PostBody",
              X = 1,
              Y = isTweet and 3 or 4,
              Width = "100%",
              Height = 5,
              Text = post.Body
            },
          }
        }

        postsView:AddObject({Type = "Separator", X = 2, Y = yOffset - 2, Width = "100%,-3"})

        newPost = postsView:AddObject(newPost)
        local bodyHeight = newPost:GetObject("PostBody").Height
        newPost.Height = (isTweet and 2 or 3) + bodyHeight

        yOffset = yOffset + newPost.Height + 3

        newPost.OnClick = function (self, event, b, x, y)
          menuView:SwitchContent("ViewPostScreen")

          Posts.ShowPost(view, menuView, post.ID)
        end
      end
    end

    postsView:AddObject({Type = "Separator", X = 2, Y = yOffset - 2, Width = "100%,-3"})
  end

  request.failure = function (url)
    ShowError("Could not connect to the server.")
  end

  request.done = function (url)
    postsView.Visible = true
    loading.Visible = false
  end
end

Posts.ShowPost = function (view, menuView, postID)
  local ok, request = SocialNet.Posts.GetAllPosts(Account.Username, Account.Password)

  if not ok then
    ShowError(request)
    return
  end

  local viewPostScreen = menuView:GetContentView("ViewPostScreen")
  local deleting = viewPostScreen:GetObject("Deleting")
  local loading = viewPostScreen:GetObject("Loading")
  local post = viewPostScreen:GetObject("Post")

  loading.Visible = true
  post.Visible = false

  request.success = function (url, data, code, rawData)
    if not data.ok then
      ShowError(data.error)
      menuView:SwitchContent("PostsScreen")

      return
    end

    for i, post in ipairs(data.data) do
      if post.ID == postID then
        viewPostScreen:GetObject("PostID").PostID = postID

        viewPostScreen:GetObject("PostAuthorAndDate").Text = "- " .. post.User .. " @ " .. post.DatePosted
        viewPostScreen:GetObject("PostBody").Text = post.Body

        if post.Type == "post" then
          viewPostScreen:GetObject("PostHeader").Visible = true
          viewPostScreen:GetObject("PostHeader").Text = post.Header

          viewPostScreen:GetObject("PostData").Y = 5
        else
          viewPostScreen:GetObject("PostHeader").Visible = false

          viewPostScreen:GetObject("PostData").Y = 4
        end

        if Account.IsLoggedInUser(post.User) then
          viewPostScreen:GetObject("DeleteButton").Visible = true
        else
          viewPostScreen:GetObject("DeleteButton").Visible = false
        end

        break
      end
    end
  end

  request.failure = function (url)
    ShowError("Could not connect to the server.")
  end

  request.done = function (url)
    loading.Visible = false
    post.Visible = true
  end
end

Posts.NewPost = function (view, menuView)
  if not Account.IsLoggedIn() then
    return
  end

  local header = view:GetObject("HeaderTextBox").Text
  local body = view:GetObject("BodyTextBox").Text
  local postType = view:GetObject("PostTypeDropDownList").SelectedOption

  view:GetObject("HeaderTextBox").Text = ""
  view:GetObject("BodyTextBox").Text = ""
  view:GetObject("PostTypeDropDownList").SelectedOption = 1

  local ok, request
  if postType == 1 then
    ok, request = SocialNet.Posts.NewPost(Account.Username, Account.Password, header, body)
  else
    ok, request = SocialNet.Posts.NewTweet(Account.Username, Account.Password, body)
  end

  if not ok then
    ShowError(request)
    return
  end

  request.success = function (url, data, code, rawData)
    if not data.ok then
      ShowError(data.error)
      return
    end

    menuView:SwitchContent("PostsScreen")
  end

  request.failure = function (url)
    ShowError("Could not connect to the server.")
  end

  request.done = function (url)

  end
end

Posts.CheckLogin = function (view)
  local loggedIn = Account.IsLoggedIn()

  if loggedIn then
    view:GetObject("PostsView").Visible = true
    view:GetObject("Loading").Visible = false
    view:GetObject("NeedLogin").Visible = false
  else
    view:GetObject("PostsView"):RemoveAllObjects()

    view:GetObject("PostsView").Visible = false
    view:GetObject("Loading").Visible = false
    view:GetObject("NeedLogin").Visible = true
  end

  return loggedIn
end