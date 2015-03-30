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