local app = require('../waffle')
app.set('debug', true)
app.get('/search', function(req, res)
   local search = req.url.args.q
   res.redirect('https://www.google.com/search?q=' .. search)
end)
app.listen()