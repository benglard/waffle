local app = require('../waffle')

app.get('/', function(req, res)
   res.send('Hello World!')
end)

app.listen()