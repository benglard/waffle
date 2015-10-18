local app = require('../waffle')
local urlfor = app.urlfor

-- Home Routes

app.module('/', 'home')
   .get('',     function(req, res) res.send 'Home' end, 'index')
   .get('test', function(req, res) res.send 'Test' end, 'test')

-- Authentication Routes

app.module('/auth', 'auth')
   .get('', function(req, res) res.redirect(urlfor 'auth.login')
      end, 'index')
   .get('/login',  function(req, res) res.send 'Login'  end, 'login')
   .get('/signup', function(req, res) res.send 'Signup' end, 'signup')

app.error(404, function(des, req, res)
   res.redirect(app.urlfor 'home.index')
end)

print(app.viewFuncs)
app.listen()