local app = require('../waffle')

app.get('/', function(req, res)
   res.send('Hello World!')
end)

app.listen({}, function() print('hello from event loop') end, 1000)