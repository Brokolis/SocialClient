Username = nil
Password = nil

function Login (username, password, success, failure, done)
  password = SocialNet.ComputeHash(password)

  local ok, request = SocialNet.Users.Login(username, password)

  if ok then
    request.success = function (url, data, code, rawData)
      if data.data == true then
        Account.Username = username
        Account.Password = password

        if success then
          success()
        end
      else
        if failure then
          failure()
        end
      end
    end

    request.failure = function (url)
      if failure then
        failure()
      end
    end

    request.done = function (url)
      if done then
        done()
      end
    end
  else
    if failure then
      failure()
    end

    if done then
      done()
    end
  end
end

function Logout ()
  Account.Username = nil
  Account.Password = nil
end

function IsLoggedIn ()
  return type(Account.Username) == "string" and type(Account.Password) == "string"
end

function IsLoggedInUser (username)
  return Account.IsLoggedIn() and Account.Username:lower() == username:lower()
end

function CleanUp ()
  Account.Username = nil
  Account.Password = nil
  Account = nil
  getfenv().Account = nil
end