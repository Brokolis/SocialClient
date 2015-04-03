local program = Bedrock

function SetProgram (p)
  program = p
end

Posts = {}

Posts.ShowPosts = function (view, postType)
  local postsView = view:GetObject("PostsView")
  local loading = view:GetObject("Loading")

  local function ShowError (msg)
    program:DisplayAlertWindow("An error occurred", msg, {"OK"})
  end

  postsView:RemoveAllObjects()

  postsView.Visible = false
  loading.Visible = true

  local ok, request = SocialNet.Posts.GetAllPosts(Account.Username, Account.Password)

  request.success = function (url, data, code, rawData)
    if not data.ok then
      ShowError(data.error)
    else
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
        end
      end

      postsView:AddObject({Type = "Separator", X = 2, Y = yOffset - 2, Width = "100%,-3"})
    end
  end

  request.failure = function (url)
    ShowError("Could not connect to the server.")
  end

  request.done = function (url)
    postsView.Visible = true
    loading.Visible = false
  end
end