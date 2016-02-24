local async = require 'async'
local paths = require 'waffle.paths'
local utils = require 'waffle.utils'
local fs = async.fs

local response = {}
response.templates = ''

response.new = function(handler, socket)
   response.body = ''
   response.headers = {}
   response.statusCode = 200
   response.handler = handler or function(body, headers, statusCode) end
   response.socket = socket
   return response
end

response.save = function()
   return {
      body = response.body,
      headers = response.headers,
      statusCode = response.statusCode
   }
end

response.load = function(data, cb, ...)
   response.body = data.body
   response.headers = data.headers
   response.statusCode = data.statusCode
   if cb ~= nil then cb(...) end
end

response.send = function(content)
   response.handler(content, response.headers, response.statusCode)
   response.body = content
end

response.resend = function(handler, socket)
   handler(response.body, response.headers, response.statusCode)
   response.handler = handler
   response.socket = socket
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
   local client = response.socket
   local _close = function(fd)
      client.close()
      fs.close(fd)
   end

   fs.open(path, 'r', '666', function(fd)
      local length = fs.bufferSize
      local offset = 0
      local function read()
         fs.read(fd, length, offset, function(data, err)
            if data == nil or err ~= nil then
               _close(fd)
               return
            end

            local ld = #data
            if ld == 0 or ld > length then
               _close(fd)
               return
            end

            offset = offset + length
            client.write(data)
            read()
         end)
      end
      read()
   end)
end

response.render = function(path, args, folder)
   args = args or {}
   local templates = response.templates or folder or ''
   local fname = paths.add(templates, path)
   response.setHeader('Content-Type', 'text/html')
   fs.readFile(fname, function(content)
      response.send(content % args)
   end)
end

response.htmlua = function(path, args, folder)
   args = args or {}
   local templates = response.templates or folder or ''
   local fname = paths.add(templates, path)
   response.setHeader('Content-Type', 'text/html')
   render(fname, args, response.send)
end

response.json = function(content)
   response.setHeader('Content-Type', 'application/json')
   response.send(async.json.encode(content))
end

response.cookie = {}

response.cookie.set = function(name, val, options)
   options = options or {}
   local path = options.path or '/'
   local expires = ''
   if options.expires ~= nil then
      local date = string.format('%s GMT',
         os.date("%a %b %d %Y %X", os.time() + options.expires))
      expires = string.format('expires=%s;', date)
   end
   if type(val) == 'table' then
      val = async.json.encode(val)
   end
   local cookie = string.format('%s=%s;%sPath=%s', name, val, expires, path)
   response.setHeader('Set-Cookie', cookie)
end

response.cookie.delete = function(name)
   local cstr = '%s=;expires=Thu, 01 Jan 1970 00:00:00 UTC;Path="/"'
   local cookie = string.format(cstr, name)
   response.setHeader('Set-Cookie', cookie)
end

response.cookie.clear = function(cookies)
   for name, val in pairs(cookies) do
      response.cookie.delete(name)
   end
end

setmetatable(response.cookie, {
   __call = function(self, ...)
      response.cookie.set(...)
   end,
})

return response