local app = require('../waffle') {
   public = './waffle',
   debug = true
}
print(app.viewFuncs)
app.listen()