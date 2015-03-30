# Waffle
Waffle is a tiny, fast, asynchronous, express-inspired web framework for Lua/Torch built on top of [ASyNC](https://github.com/clementfarabet/async).

## Hello World
```lua
local app = require('../waffle')

app.get('/', function(req, res)
   res.send('Hello World!')
end)

app.listen()
```