local app = require('../waffle').CmdLine()

app.get('/', function(req, res)
   if app.session.type == 'memory' then
      local n = app.session.n or 0
      res.send('#' .. n)
      if n > 19 then app.session.n = nil
      else app.session.n = n + 1 end
   else
      app.session:get('n', function(n)
         res.send('#' .. n)
         if n > 19 then app.session:delete('n')
         else app.session.n = n + 1 end
      end, 0)
   end
end)

app.listen()