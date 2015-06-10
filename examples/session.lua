local app = require('../waffle') --.CmdLine()
local async = require 'async'

-- Test

--[[app.session('cache')
app.session['test'] = true
print(app.session.test)

app.session.data = nil

app.session('redis')
async.setTimeout(100, function()
   app.session['test'] = true
   app.session:get('test', function(data)
      print(data)
   end)
end)]]

app.session('redis')

app.get('/', function(req, res)
   app.session:get('n', function(n)
      if n == nil then n = 0 end
      n = tonumber(n)
      res.send('#' .. n)
      if n > 19 then
         app.session:delete('n')
      else
         app.session.n = n + 1
      end
   end)
end)

app.listen()