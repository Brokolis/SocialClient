LogFile = "log.txt"

function Log (...)
  local str = os.clock() .. ": "

  local isFirst = true
  for i, t in ipairs(arg) do
    str = str .. (isFirst and "" or " | ") .. tostring(t)
    isFirst = false
  end

  AppendLog(str)
end

function AppendLog (text)
  local file = fs.open(LogFile, "a")

  file.writeLine(text)
  file.close()
end

function ClearLog ()
  local file = fs.open(LogFile, "w")
  
  file.close()
end