local dkjson = require('lib.dkjson.dkjson')

local function test()
  print('ayy lmao')
end

print(dkjson.encode({ testObj = test }, { exception = function() return true end }))
