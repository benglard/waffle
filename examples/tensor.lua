--[[
This example shows how to transform an
uploaded image into a torch Tensor.
]]

local app = require 'waffle'

app.get('/', function(req, res)
   res.send(html { body { form {
      method = 'POST',
      enctype = 'multipart/form-data',
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

app.post('/', function(req, res)
   local img = req.form.file:toImage()
   local m = img:mean()
   res.send('Image mean: ' .. m)
end)

app.listen()