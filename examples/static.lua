local app = require('../waffle')
app.set('public', '.')
print(app.viewFuncs)
app.listen()