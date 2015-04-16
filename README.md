# Waffle
Waffle is a tiny, fast, asynchronous, express-inspired web framework for Lua/Torch built on top of [ASyNC](https://github.com/clementfarabet/async).

Waffle's performance is impressive. On [this test](https://medium.com/@tschundeee/express-vs-flask-vs-go-acc0879c2122), given in ```examples/fib.lua```, Waffle reaches over 20,000 requests/sec (> 2x Node+express, ~1/2x Go).

## Hello World
```lua
local app = require('../waffle')

app.get('/', function(req, res)
   res.send('Hello World!')
end)

app.listen()
```

## Requests
```lua
app.get('/', function(req, res)
   res.send('Getting...')
end)

app.post('/', function(req, res)
   res.send('Posting...')
end)

app.put('/', function(req, res)
   res.send('Putting...')
end)

app.delete('/', function(req, res)
   res.send('Deleting...')
end)
```

## Static Files
```lua
local app = require('../waffle')
app.set('public', '.')
app.listen()
```

## URL Parameters
```lua
app.get('/user/(%d+)', function(req, res)
   local userId = tonumber(req.params[1])
   local users = {
      [1] = 'Lua',
      [2] = 'JavaScript',
      [3] = 'Python'
   }
   res.send(string.format('Hello, %s', users[userId] or 'undefined'))
end)

app.get('/user/(%a+)', function(req, res)
   local name = req.params[1]
   res.send(string.format('Hello, %s', name))
end)
```

## HTML Rendering
```html
<html>
<head></head>
<body>
  <h3>Welcome, ${name}</h3>
  <p>Time: ${time}</p>
</body>
</html>
```
```lua
app.get('/render/(%a+)', function(req, res)
   res.render('./examples/template.html', {
      name = req.params[1],
      time = os.time()
   })
end)
```

## Query Paramaters
```lua
app.get('/search', function(req, res)
   local search = req.url.args.q
   res.redirect('https://www.google.com/search?q=' .. search)
end)
```

## Error Handling
```lua
app.error(404, function(description, req, res)
   local url = string.format('%s%s', req.headers.host, req.url.path)
   res.status(404).send('No page found at ' .. url)
end)

app.error(500, function(description, req, res)
   if app.properties.debug then
      res.status(500).send(description)
   else
      res.status(500).send('500 Error')
   end
end)
```

## JSON
```lua
app.get('/', function(req, res)
   res.json({test=true})
end)
```

## Async Debugging
```lua
app = require('../waffle')
a = 1
b = 2
c = 3
app.repl()
app.listen()
```

```lua
th> async = require 'async'
                                                                      [0.0133s]  
th> async.repl.connect({host='127.0.0.1', port=8081})
                                                                      [0.0005s]  
th> async.go()
127.0.0.1:8081> a
1  
127.0.0.1:8081> b
2  
127.0.0.1:8081> c
3  
127.0.0.1:8081> app
{ ... }
127.0.0.1:8081> _G
{ ... }
```

## TODO
* Named URL route parameters
* Enhanced HTML templating engine
* Sessions/cookies
* Testing
* Documentation
* Websockets?
* Rewrite in C for extra performance?
* more?