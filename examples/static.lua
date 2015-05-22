local app = require('../waffle') {
   public = '.'
}
--app.set('public', '.')
print(app.viewFuncs)
app.listen()