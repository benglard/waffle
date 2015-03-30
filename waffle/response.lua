local async = require 'async'
local response = {}

response.new = function()
   response.headers = {}
   response.statusCode = 200
   response.handler = function(body, headers, statusCode) end
   return response
end

response.send = function(content)
   response.handler(content, response.headers, response.statusCode)
end

response.setHandler = function(handler)
   response.handler = handler
end

response.setHeader = function(name, value)
   response.headers[name] = value
   return response
end
response.header = response.setHeader

response.setStatus = function(status)
   response.statusCode = status
   return response
end
response.status = response.setStatus

response.location = function(url)
   response.setHeader('Location', url)
end

response.redirect = function(url)
   response.setStatus(302)
   response.location(url)
   response.send('')
end

response.sendFile = function(path)
   async.fs.readFile(path, function(content)
      response.send(content)
   end)
end

return response