local app = require('../waffle')

app.get('/', function(req, res)
   res.json {
      test = true,
      string = 'hello'
   }
end)

db = {
   [1] = {
      Name = 'First1 Last1',
      City = 'City1',
      State = 'State1'
   },
   [2] = {
      Name = 'First2 Last2',
      City = 'City2',
      State = 'State2'
   },
   [3] = {
      Name = 'First3 Last3',
      City = 'City3',
      State = 'State3'
   }
}

app.get('/user/(%d+)', function(req, res)
   local userId = tonumber(req.params[1])
   local user = db[userId]
   if user == nil then
      app.abort(400, 'User not found', req, res)
   else
      res.json(user)
   end
end)

app.repl()
app.listen()

--[[ To test repl, try this:
th> async = require 'async'
                                                                      [0.0131s]  
th> async.repl.connect({host='127.0.0.1', port=8081})
                                                                      [0.0004s]  
th> async.go()
127.0.0.1:8081> db
{
  1 : 
    {
      State : "State1"
      Name : "First1 Last1"
      City : "City1"
    }
  2 : 
    {
      State : "State2"
      Name : "First2 Last2"
      City : "City2"
    }
  3 : 
    {
      State : "State3"
      Name : "First3 Last3"
      City : "City3"
    }
}
]]