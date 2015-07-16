local app = require('../waffle') { 
   templates = 'examples',
   autocache = true
}

app.get('/', function(req, res)
   res.htmlua('luatemp.html', { name = 'waffle', time = os.time() })
end)

app.get('/i', function(req, res)
   res.send(
      html.html {
         html.head {
            html.title 'Title'
         },
         html.body {
            html.p 'Hello World!'
         }
      }
   )
end)

app.error(500, function(des, req, res)
   print(des)
end)

app.listen()