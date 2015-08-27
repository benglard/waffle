# Waffle
Waffle is a fast, asynchronous, express-inspired web framework for Lua/Torch built on top of [ASyNC](https://github.com/clementfarabet/async).

Waffle's performance is impressive. On [this test](https://medium.com/@tschundeee/express-vs-flask-vs-go-acc0879c2122), given in ```examples/fib.lua```, Waffle reaches over 20,000 requests/sec (2-4 x Node+express, 1/2 x multithreaded Go). With automatic caching enabled, Waffle can reach over 26,000 requests/sec, equaling single-threaded Go.

This project depends on [htmlua](https://github.com/benglard/htmlua) for HTML templating.

## Installation

```
> (sudo) luarocks install https://raw.githubusercontent.com/benglard/htmlua/master/htmlua-scm-1.rockspec
> (sudo) luarocks install https://raw.githubusercontent.com/benglard/waffle/master/waffle-scm-1.rockspec
```

## Hello World
```lua
local app = require('waffle')

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

There are two options for html rendering. The first involves writing actual html and using the string interp utility provided, ${variable-name}.

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

The second, preferable, more powerful way involves writing htmlua scripts, either as separate template files, or inline in view functions.


```lua
-- luatemp.html
local base = extends 'examples/baseluatemp.html'
return block(base, 'content'){
   h3 'Welcome, ${name}',
   p 'Time: ${time}',
   ul(each([[${users}]], li)),
   img {
      src = 'https://www.google.com/images/srpr/logo11w.png'
   }
}
```

```lua
-- htmlua.lua
-- Template
app.get('/', function(req, res)
   res.htmlua('luatemp.html', {
      name = 'waffle',
      time = os.time(),
      users = {'lua', 'python', 'javascript'}
   })
end)

-- Inline
app.get('/i', function(req, res)
   res.send(html {
      head { title 'Title' },
      body { p 'Hello World!' }
   })
end)
```

The htmlua page provides further documentation and examples.

## Form Parsing

```lua
app.get('/m', function(req, res)
   res.send(html { body { form {
      action = '/m',
      method = 'POST',
      enctype = 'multipart/form-data',
      p { input {
         type = 'text',
         name = 'firstname',
         placeholder = 'First Name'
      }},
      p { input {
         type = 'text',
         name = 'lastname',
         placeholder = 'Last Name'
      }},
      p { input {
         type = 'file',
         name = 'file' 
      }},
      p { input {
         type = 'submit',
         'Upload'
      }}
   }}})
end)

app.post('/m', function(req, res)
   local name = string.format('%s %s', req.form.firstname, req.form.lastname)
   local path = paths.add(os.getenv('HOME'), req.form.file.filename)
   req.form.file:save{path=path}
   res.send('Saved to ' .. path)
end)
```

## Websockets

To implement a websocket server, call app.ws with a url path and a function accepting a single table. You can then define checkorigin, onopen, onmessage, onpong, and onclose for that table, to control the server-side websocket connection.

Benchmarking websockets is tricky, but on first attempts, waffle seems competitive with similar node libraries.

```lua
local app = require('waffle')
local js = [[
var ws = new WebSocket("ws://127.0.0.1:8080/ws/");
function print() { console.log(ws.readyState); }
ws.onopen = function() {
   console.log("opened");
   print();
   ws.send("Hello");
}

ws.onmessage = function(msg) {
   console.log(msg);
   setTimeout(function() { ws.close(); }, 1000);
}

ws.onclose = function(event) {
   console.log(event);
   console.log("closed");
   print();
}
]]

app.get('/', function(req, res)
   res.send(html { body {
      p 'Hello, World',
      script { type='text/javascript', js }
   }})
end)

app.ws('/ws', function(ws)
   ws.checkorigin = function(origin) return origin == 'http://127.0.0.1:8080' end
   ws.onopen = function(req) print('/ws/opened') end
   ws.onmessage = function(data)
      print(data)
      ws:write('World')
      ws:ping('test')
   end
   ws.onpong = function(data) print(data) end
   ws.onclose = function(req) print('/ws/closed') end
end)
```

## Query Paramaters
```lua
app.get('/search', function(req, res)
   local search = req.url.args.q
   res.redirect('https://www.google.com/search?q=' .. search)
end)
```

## Static Files
```lua
local app = require('waffle')
app.set('public', '.')
app.listen()
```

## Error Handling
```lua
app.error(404, function(description, req, res)
   local url = string.format('%s%s', req.headers.host, req.url.path)
   res.status(404).send('No page found at ' .. url)
end)

app.error(500, function(description, req, res)
   if app.debug then
      res.status(500).send(description)
   else
      res.status(500).send('500 Error')
   end
end)
```

## Cookies
```lua
app.get('/cookie', function(req, res)
   local c = req.cookies.counter or -1
   res.cookie('counter', tonumber(c) + 1)
   res.send('#' .. c)
end)
```

## Sessions

Waffle has both in-memory and redis sessions using [redis-async](https://github.com/ocallaco/redis-async).

```lua
local app = require('waffle')
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
```

## JSON
```lua
app.get('/', function(req, res)
   res.json{test=true}
end)
```

## Command Line Options

Allows you to write every currently possible waffle application property as a command line option, and have it handled seamlessly. 

```lua
local app = require('waffle').CmdLine()
```

```
> th examples/cmdline.lua --debug --print --port 3000 --templates examples/
```

## Async Debugging
```lua
app = require('waffle')
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

## wafflemaker (executable)

The wafflemaker executable can be used:

* to create project directories in MVC style, like so:

```
wafflemaker --create name_of_project
```

* to serve static files akin to running ```python -m SimpleHTTPServer```, but with much, much, much better performance (almost 20x requests/sec).

```
cd folder/i/want/to/serve
wafflemaker --serve
```

## Larger example (with autocache)

When autocache is set to true, waffle will automatically store the response body, headers, and status code, and reuse them when a request is sent to the same http method/url. So, for instance, when a request is sent to GET/10 in the example below, it will only have to compute fib(10) once. Note that ```app.urlCache``` is set by default to cache the data of the last 20 method/url requests.

```lua
local app = require('../waffle') {
   debug = true,
   autocache = true
}

fib = function(n)
   if n == 0 then return 0
   elseif n == 1 then return 1
   else return fib(n-1) + fib(n-2)
   end
end

app.get('/(%d+)', function(req, res)
   local n = req.params[1]
   local result = fib(tonumber(n))
   res.header('Content-Type', 'text/html')
   res.send('ASyNC + Waffle<hr> fib(' .. n .. '): ' .. result)
end)

app.listen()
```

## TODO
* Named URL route parameters
* Automatic caching of static files
* Testing
* Documentation
* more?