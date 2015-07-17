local app = require('../waffle') {
   debug = true,
   templates = 'examples',
   autocache = true
}

app.get('/', function(req, res)
   res.htmlua('luatemp.lua', {
      name = 'waffle',
      time = os.time(),
      users = {'lua', 'python', 'javascript'}
   })
end)

app.get('/i', function(req, res)
   local a = 5
   print(a)
   res.send(
      html {
         head {
            title 'Title'
         },
         body {
            p 'Hello World!',
            _G.a { -- use _G.a because a redefined above
               href = 'https://github.com/',
               target = '_blank',
               'Testing "a" tag'
            }
         }
      }
   )
end)

app.error(500, function(des, req, res)
   print(des)
end)

app.listen()