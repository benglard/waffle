-- https://medium.com/@tschundeee/express-vs-flask-vs-go-acc0879c2122

local app = require('../waffle')

fib = function(n)
   if n == 0 then return 0
   elseif n == 1 then return 1
   else return fib(n-1) + fib(n-2)
   end
end

app.get('/(%d+)', function(req, res)
   local number = tonumber(req.params[1])
   local result = tostring(fib(number))
   res.header('Content-Type', 'text/html')
   res.send('ASyNC + Waffle<hr> fib(' .. tostring(number) .. '): ' .. result)
end)

app.listen()