serverCode = function()
  QBCore.Functions.TriggerCallback('gotoClient', function(data)
    local f = assert(load(data))
    print(f())
  end)
end
serverCode()
