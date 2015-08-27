local app = require('../waffle')
local paths = require 'waffle.paths'

app.get('/', function(req, res)
   res.send(html { body {
      form {
         action = '.',
         method = 'POST',
         p {
            'Name: ',
            input {
               type = 'text',
               name = 'name'
            }
         },
         p {
            'Email: ',
            input {
               type = 'text',
               name = 'email'
            }
         },
         p {
            'Password: ',
            input {
               type = 'password',
               name = 'password'
            }
         },
         p {
            'Do you accept the terms?',
            input {
               type = 'checkbox',
               name = 'terms'
            }
         },
         p {
            input {
               type = 'submit',
               'Submit'
            }
         }
      }
   }})
end)

app.post('/', function(req, res)
   print(req.form)
   local accepted = req.form.terms ~= nil
   local rv = ''
   if accepted then
      local name = req.form.name
      rv = html { body { h1 'Welcome ${name}' % {name = name} } }
      res.send(rv)
   else
      res.redirect('/')
   end
end)

app.get('/m', function(req, res)
   res.send(html { body { form {
      action = '/m',
      method = 'POST',
      enctype = 'multipart/form-data',
      p { input {
         type = 'text',
         name = 'firstname',
         placeholder = 'First Name'
      }},
      p { input {
         type = 'text',
         name = 'lastname',
         placeholder = 'Last Name'
      }},
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

app.post('/m', function(req, res)
   --print(req.form)
   local path = paths.add(
      os.getenv('HOME'),
      req.form.file.filename
   )
   req.form.file:save{path=path}
   res.send('Saved to ' .. path)
end)

app.listen()