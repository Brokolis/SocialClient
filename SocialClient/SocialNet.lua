--[[
    SocialNet API written by Mantas Klimašauskas (MKlegoman357)

    This is an API written for DannySMc's Social Net web API. Although, DannySMc has written his
    own API I decided that it didn't fit my needs, so I wrote my own API.
--]]

local SocialNet = {}

-- The base URL for CC Systems
SocialNet.baseUrl = "https://ccsystems.dannysmc.com/ccsystems.php"

-- Holds all unfinished http requests
SocialNet.requests = {}

--[[
    Makes an asynchronous request to the server. Use request events to deal with the request.

    Returns: request (table) - the request to the web page.

    The third parameter 'unserializer' is the unserializer function that will be given the response to unserialize it.
    The default unserializer is textutils.unserialize, However, most SocialNet methods use the SocialNet.BasicUnserialize
    function. You can (and should) add 'request events' to the request to deal with it. Request events are just
    functions (callbacks) put inside the request table. There are three events (function parameters are put in parenthesis):
      * success (url, unserializedData, responseCode, rawData) - ran after 'http_success' event for this request
      * failure (url) - ran after 'http_failure' event for this request
      * done (url) - ran after both 'http_success' and 'http_failure' events, right *after* 'success' and 'failure'
        callbacks have been ran.
--]]
SocialNet.Request = function (parameters, headers, unserializer, url)
  parameters = parameters or {}
  url = url or SocialNet.baseUrl

  local postParams = ""

  local isFirst = true
  for key, param in pairs(parameters) do
    postParams = postParams .. (isFirst and "" or "&") .. textutils.urlEncode(tostring(key)) .. "=" .. textutils.urlEncode(tostring(param))
    isFirst = false
  end

  -- allows events: 'success' (http_success), 'failure' (http_failure) and 'done' (http_success and http_failure)
  local request = {
    url = url,
    unserializer = unserializer or textutils.unserialize
  }

  table.insert(SocialNet.requests, request)

  http.request(url, postParams, headers)

  return request
end

--[[
    Takes in raw data and tries to unserialize it with textutils.unserialize. Returns a table with two keys: 'ok' and 'data' or 'error'.
    If unserializes the raw data successfully then 'ok' is set to true and 'data' is set to whatever the unserialized raw data
    is. Otherwise sets 'ok' to false and sets 'error' to the raw data.
--]]
SocialNet.BasicUnserialize = function (rawData)
  local data = textutils.unserialize(rawData)

  if data == nil then
    return {ok = false, error = rawData}
  end

  return {ok = true, data = data}
end

--[[
    Handles the passed event. Required to be passed http events for requests to function properly

    Returns: handled (boolean) - wether the event was handled or not
--]]
SocialNet.EventHandler = function (event, ...)
  local params = {...}

  if event == "http_success" then
    for i, request in ipairs(SocialNet.requests) do
      if request.url == params[1] then
        local code = params[2].getResponseCode()
        local rawData = params[2].readAll()

        params[2].close()

        local data = request.unserializer(rawData)

        if request.success then
          request.success(request.url, data, code, rawData)
        end

        if request.done then
          request.done(request.url)
        end

        table.remove(SocialNet.requests, i)

        return true
      end
    end
  elseif event == "http_failure" then
    for i, request in ipairs(SocialNet.requests) do
      if request.url == params[1] then
        if request.failure then
          request.failure(request.url)
        end

        if request.done then
          request.done(request.url)
        end

        table.remove(SocialNet.requests, i)

        return true
      end
    end
  end

  return false
end

--[[ Wrappers for the SocialNet.Request function ]]--

-- User managment functions
SocialNet.Users = {}

--[[
    Takes the username and the sha256 hash of the password
--]]
SocialNet.Users.Login = function (username, password)
  local parameters = {
    ccsys = "user",
    cccmd = "login",
    username = username,
    password = password
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the new username, the sha256 hash of the new password and the new email
--]]
SocialNet.Users.Register = function (username, password, email)
  local parameters = {
    ccsys = "user",
    cccmd = "register",
    username = username,
    password = password,
    email = email
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username and the sha256 hash of the password
--]]
SocialNet.Users.List = function (username, password)
  local parameters = {
    ccsys = "user",
    cccmd = "list",
    username = username,
    password = password
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

-- App Store managment functions
SocialNet.Store = {}

SocialNet.Store.ListAllApps = function ()
  local parameters = {
    ccsys = "appstore",
    cccmd = "list"
  }

  local function unserialize (rawData)
    local data = SocialNet.BasicUnserialize(rawData)

    if data.ok then
      local apps = {}

      for i, app in ipairs(data.data) do
        apps[#apps + 1] = {
          ID = app[1],
          Name = app[2],
          Description = app[3],
          Version = app[4],
          Category = app[5],
          DownloadUrl = app[6],
          User = app[7],
          IndexID = app[8],
          Visibility = app[9]
        }
      end

      data.data = apps
    end

    return data
  end

  return true, SocialNet.Request(parameters, nil, unserialize)
end

--[[
    Takes the username, the sha256 hash of the password, the new app's name, description, version, file contents, category and status ('public' or 'private')
--]]
SocialNet.Store.UploadApp = function (username, password, appName, appDescription, appVersion, appFile, appCategory, appStatus)
  local parameters = {
    ccsys = "appstore",
    cccmd = "upload",
    username = username,
    password = password,
    filename = appName,
    filedesc = appDescription,
    filevers = appVersion,
    filedata = appFile,
    filecate = appCategory,
    filestat = appStatus
  }

  return true, SocialNet.Request(patameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, the sha256 hash of the password, the app's name, new verion, new file contents and new status
--]]
SocialNet.Store.UpdateApp = function (username, password, appName, appVersion, appFile, appStatus)
  local parameters = {
    ccsys = "appstore",
    cccmd = "update",
    username = username,
    password = password,
    filename = appName,
    filevers = appVersion,
    filedata = appFile,
    filestat = appStatus
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, the sha256 hash of the password, the app's name, new description, new version and new status
--]]
SocialNet.Store.EditApp = function (username, password, appName, appDescription, appVersion, appStatus)
  local parameters = {
    ccsys = "appstore",
    cccmd = "edit",
    username = username,
    password = password,
    filename = appName,
    filedesc = appDescription,
    filevers = appVersion,
    filestat = appStatus
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the app's you want to get comments of ID
--]]
SocialNet.Store.GetAppComments = function (appID)
  local parameters = {
    ccsys = "appstore",
    cccmd = "viewcomments",
    appid = appID
  }

  -- TODO: make a custom unserializer
  local function unserialize (rawData)
    local data = SocialNet.BasicUnserialize(rawData)

    if data.ok then
      local comments = {}

      for i, comment in ipairs(data.data) do
        comments[#comments + 1] = {

        }
      end

      data.data = comments
    end

    return data
  end

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, the sha256 hash of the password, the app's ID, and the new comment
--]]
SocialNet.Store.NewAppComment = function (username, password, appID, comment)
  local parameters = {
    ccsys = "appstore",
    cccmd = "addcomments",
    username = username,
    password = password,
    appid = appID,
    comment = comment
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

-- Post managment functions
SocialNet.Posts = {}

--[[
    Takes the username, the sha256 hash of the password, the new post's header (MAX 1024) and body (MAX 4096)
--]]
SocialNet.Posts.NewPost = function (username, password, header, body)
  if #header > 1024 then
    return false, "Header is too big (max 1024 characters)."
  elseif #body > 4096 then
    return false, "Body is too big (max 4096 characters)."
  end

  local parameters = {
    ccsys = "social",
    cccmd = "post_new",
    username = username,
    password = password,
    type = "post",
    header = header,
    message = body
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, the sha256 hash of the password and the new post's body (MAX 255)
--]]
SocialNet.Posts.NewTweet = function (username, password, body)
  if #body > 255 then
    return false, "Body is too big (max 255 characters)."
  end

  local parameters = {
    ccsys = "social",
    cccmd = "post_tweet",
    username = username,
    password = password,
    type = "tweet",
    message = body
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username and the sha256 hash of the password
--]]
SocialNet.Posts.GetAllPosts = function (username, password)
  local parameters = {
    ccsys = "social",
    cccmd = "post_getall",
    username = username,
    password = password
  }

  local function unserialize (rawData)
    local data = SocialNet.BasicUnserialize(rawData)

    if data.ok then
      local posts = {}

      for i, post in ipairs(data.data) do
        posts[#posts + 1] = {
          ID = post[1],
          Type = post[2],
          User = post[3],
          Header = post[4],
          Body = post[5],
          DatePosted = post[6]
        }
      end

      table.sort(posts, function (a, b)
        return tonumber(a.ID) > tonumber(b.ID)
      end)

      data.data = posts
    end

    return data
  end

  return true, SocialNet.Request(parameters, nil, unserialize)
end

--[[
    Takes the username, the sha256 hash of the password and the post's you want to delete ID
--]]
SocialNet.Posts.DeletePost = function (username, password, postID)
  local parameters = {
    ccsys = "social",
    cccmd = "post_delete",
    username = username,
    password = password,
    postid = postID
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

-- Profile managment functions
SocialNet.Profile = {}

--[[
    Takes the username, the sha256 hash of the password and the user's you want to get profile of username
--]]
SocialNet.Profile.GetProfileInfo = function (username, password, userUsername)
  local parameters = {
    ccsys = "social",
    cccmd = "profile_get",
    username = username,
    password = password,
    usertoget = userUsername
  }

  local function unserialize (rawData)
    local data = SocialNet.BasicUnserialize(rawData)

    if data.ok then
      local info = {
        ID = data.data[1],
        User = data.data[2],
        FullName = data.data[3],
        Age = data.data[4],
        Biography = data.data[5],
        ForumsUsername = data.data[6]
      }

      data.data = info
    end

    return data
  end

  return true, SocialNet.Request(parameters, nil, unserialize)
end

--[[
    Takes the username, the sha256 shash of the password, the full name, age, biography and ComputerCraft Forum's username
--]]
SocialNet.Profile.EditProfile = function (username, password, fullName, age, biography, forumsUsername)
  local parameters = {
    ccsys = "social",
    cccmd = "profile_edit",
    username = username,
    password = password,
    fullname = fullName,
    age = age,
    bio = biography,
    forumsusername = forumsUsername
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, sha256 hash of the password and the user's you want to get friend list of username
--]]
SocialNet.Profile.GetFriendList = function (username, password, userUsername)
  local parameters = {
    ccsys = "social",
    cccmd = "friends_get",
    username = username,
    password = password,
    usertoget = userUsername
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, the sha256 shash of the password and the updated friend list
--]]
SocialNet.Profile.UpdateFriendList = function (username, password, friendList)
  local parameters = {
    ccsys = "social",
    cccmd = "friends_add",
    username = username,
    password = password,
    friendslist = "{" .. table.concat(friendList, ",") .. "}"
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

-- Global chat managment functions
SocialNet.GlobalChat = {}

--[[
    Takes the username, the sha256 shash of the password and the new message (MAX 255)
--]]
SocialNet.GlobalChat.NewMessage = function (username, password, message)
  if #message > 255 then
    return false, "Message is too big (max 255 characters)."
  end

  local parameters = {
    ccsys = "social",
    cccmd = "chat_global_new",
    username = username,
    password = password,
    message = message
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username and the sha256 shash of the password
--]]
SocialNet.GlobalChat.GetAllMessages = function (username, password)
  local parameters = {
    ccsys = "social",
    cccmd = "chat_global_get",
    username = username,
    password = password
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

-- Group chat managment functions
SocialNet.GroupChat = {}

--[[
    Takes the username, the sha256 shash of the password, the group's name and the new message (MAX 255)
--]]
SocialNet.GroupChat.NewMessage = function (username, password, groupName, message)
  if #message > 255 then
    return false, "Message is too big (max 255 characters)."
  end

  local parameters = {
    ccsys = "social",
    cccmd = "chat_group_new",
    username = username,
    password = password,
    groupname = groupName,
    message = message
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, the sha256 shash of the password and the group's name
--]]
SocialNet.GroupChat.GetAllMessages = function (username, password, groupName)
  local parameters = {
    ccsys = "social",
    cccmd = "chat_group_get",
    username = username,
    password = password,
    groupname = groupName
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

-- Private chat managment functions
SocialNet.PrivateChat = {}

--[[
    Takes the username, the sha256 shash of the password, the recipient's username and the new message
--]]
SocialNet.PrivateChat.NewMessage = function (username, password, recipientUsername, message)
  if #message > 255 then
    return false, "Message is too big (max 255 characters)."
  end

  local parameters = {
    ccsys = "social",
    cccmd = "chat_pm_new",
    username = username,
    password = password,
    recipient = recipientUsername,
    message = message
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    Takes the username, the sha256 shash of the password and the recipient's username
--]]
SocialNet.PrivateChat.GetAllMessages = function (username, password, recipientUsername)
  local parameters = {
    ccsys = "social",
    cccmd = "chat_pm_get",
    username = username,
    password = password,
    recipient = recipientUsername
  }

  return true, SocialNet.Request(parameters, nil, SocialNet.BasicUnserialize)
end

--[[
    This function takes a string and returns its hash. Current hashing algorythm: sha256 by GravityScore.
--]]
SocialNet.ComputeHash = function (plaintext)
  --  
  --  Adaptation of the Secure Hashing Algorithm (SHA-244/256)
  --  Found Here: http://lua-users.org/wiki/SecureHashAlgorithm
  --  
  --  Using an adapted version of the bit library
  --  Found Here: https://bitbucket.org/Boolsheet/bslf/src/1ee664885805/bit.lua
  --  

  local MOD = 2^32
  local MODM = MOD-1

  local function memoize(f)
    local mt = {}
    local t = setmetatable({}, mt)
    function mt:__index(k)
      local v = f(k)
      t[k] = v
      return v
    end
    return t
  end

  local function make_bitop_uncached(t, m)
    local function bitop(a, b)
      local res,p = 0,1
      while a ~= 0 and b ~= 0 do
        local am, bm = a % m, b % m
        res = res + t[am][bm] * p
        a = (a - am) / m
        b = (b - bm) / m
        p = p*m
      end
      res = res + (a + b) * p
      return res
    end
    return bitop
  end

  local function make_bitop(t)
    local op1 = make_bitop_uncached(t,2^1)
    local op2 = memoize(function(a) return memoize(function(b) return op1(a, b) end) end)
    return make_bitop_uncached(op2, 2 ^ (t.n or 1))
  end

  local bxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})

  local function bxor(a, b, c, ...)
    local z = nil
    if b then
      a = a % MOD
      b = b % MOD
      z = bxor1(a, b)
      if c then z = bxor(z, c, ...) end
      return z
    elseif a then return a % MOD
    else return 0 end
  end

  local function band(a, b, c, ...)
    local z
    if b then
      a = a % MOD
      b = b % MOD
      z = ((a + b) - bxor1(a,b)) / 2
      if c then z = bit32_band(z, c, ...) end
      return z
    elseif a then return a % MOD
    else return MODM end
  end

  local function bnot(x) return (-1 - x) % MOD end

  local function rshift1(a, disp)
    if disp < 0 then return lshift(a,-disp) end
    return math.floor(a % 2 ^ 32 / 2 ^ disp)
  end

  local function rshift(x, disp)
    if disp > 31 or disp < -31 then return 0 end
    return rshift1(x % MOD, disp)
  end

  local function lshift(a, disp)
    if disp < 0 then return rshift(a,-disp) end 
    return (a * 2 ^ disp) % 2 ^ 32
  end

  local function rrotate(x, disp)
      x = x % MOD
      disp = disp % 32
      local low = band(x, 2 ^ disp - 1)
      return rshift(x, disp) + lshift(low, 32 - disp)
  end

  local k = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  }

  local function str2hexa(s)
    return (string.gsub(s, ".", function(c) return string.format("%02x", string.byte(c)) end))
  end

  local function num2s(l, n)
    local s = ""
    for i = 1, n do
      local rem = l % 256
      s = string.char(rem) .. s
      l = (l - rem) / 256
    end
    return s
  end

  local function s232num(s, i)
    local n = 0
    for i = i, i + 3 do n = n*256 + string.byte(s, i) end
    return n
  end

  local function preproc(msg, len)
    local extra = 64 - ((len + 9) % 64)
    len = num2s(8 * len, 8)
    msg = msg .. "\128" .. string.rep("\0", extra) .. len
    assert(#msg % 64 == 0)
    return msg
  end

  local function initH256(H)
    H[1] = 0x6a09e667
    H[2] = 0xbb67ae85
    H[3] = 0x3c6ef372
    H[4] = 0xa54ff53a
    H[5] = 0x510e527f
    H[6] = 0x9b05688c
    H[7] = 0x1f83d9ab
    H[8] = 0x5be0cd19
    return H
  end

  local function digestblock(msg, i, H)
    local w = {}
    for j = 1, 16 do w[j] = s232num(msg, i + (j - 1)*4) end
    for j = 17, 64 do
      local v = w[j - 15]
      local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
      v = w[j - 2]
      w[j] = w[j - 16] + s0 + w[j - 7] + bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
    end

    local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
    for i = 1, 64 do
      local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
      local maj = bxor(band(a, b), band(a, c), band(b, c))
      local t2 = s0 + maj
      local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
      local ch = bxor (band(e, f), band(bnot(e), g))
      local t1 = h + s1 + ch + k[i] + w[i]
      h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
    end

    H[1] = band(H[1] + a)
    H[2] = band(H[2] + b)
    H[3] = band(H[3] + c)
    H[4] = band(H[4] + d)
    H[5] = band(H[5] + e)
    H[6] = band(H[6] + f)
    H[7] = band(H[7] + g)
    H[8] = band(H[8] + h)
  end

  local function sha256(msg)
    msg = preproc(msg, #msg)
    local H = initH256({})
    for i = 1, #msg, 64 do digestblock(msg, i, H) end
    return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
      num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
  end

  return sha256(plaintext)
end

return SocialNet