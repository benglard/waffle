--[[ 
Try running like

> th examples/cmdline.lua --debug --print --port 3000 --templates examples/ --autocache

And then visiting http://127.0.0.1:3000/... in your web browser
]]

local app = require('../waffle').CmdLine()

app.get('/', function(req, res) res.send 'Hello World!' end)

app.get('/error', function(req, res) b = a + 5 end)

app.get('/render', function(req, res)
   local name = ''
   local  r = math.random()
   if r < 0.333 then name = 'Lua'
   elseif r < 0.666 then name = 'Python'
   else name = 'JavaScript' end
   res.render('template.html', { name = name, time = os.time() })
end)

app.error(500, function(des, req, res)
   if app.debug then
      res.status(500).send(des)
   else
      res.status(500).send('500 Error')
   end
end)

app.listen()