local ffi = require 'ffi'
local async = require 'async'
local encodings = require 'waffle.encodings'
local gmOk, gm = pcall(require, 'image')
local afs = async.fs
local http_codes = async.http.codes

local _getcookies = function(self)
   self.cookies = {}
   local c = self.headers.cookie
   if c then
      for param in string.gsplit(c, '; ') do
         local arg = string.split(param, '=')
         self.cookies[arg[1]] = arg[2]
      end
   end
end

local _save = function(self, options, cb)
   options = options or {}
   local path = options.path or self.filename
   local binary = options.binary or self.binary
   local flag = 'w'
   if binary then flag = 'w+' end
   cb = cb or function(err) end

   afs.open(path, flag, '666', function(fd)
      afs.write(fd, self.data, function(err)
         cb(err)
         afs.close(fd)
      end)
   end)
end

local _totensor = function(self, ...)
   if gmOk then
     local b = torch.ByteTensor(string.len(self.data))
     ffi.copy(b:data(), self.data, b:size(1))
     return image.decompress(b, 3, 'float')
   else
      return nil
   end
end

local _toimage = function(self)
   return _totensor(self, 'float','RGB','DHW')
end

local _getform = function(self)
   self.form = {}
   local isjson = self.headers['content-type'] == 'application/json'
   if isjson then return end

   if self.body ~= '' then
      local rbody = self.body
      if type(rbody) == 'table' then
         -- Multipart form encoded
         for key, value in pairs(rbody) do
            local notfile = value.filename == nil
            if notfile then
               self.form[key] = value.data
            else
               local ctype = value['content-type']
               local binary = ctype:find('text') == nil
               self.form[key] = {
                  data = value.data,
                  type = ctype,
                  filename = value.filename,
                  binary = binary,
                  save = _save,
                  toTensor = _totensor,
                  toImage = _toimage
               }
            end
         end
      else
         -- URL Encoded
         for param in string.gsplit(rbody, '&') do
            local arg = string.split(param, '=')
            if #arg > 0 then
                self.form[arg[1]] = encodings.urldecode(arg[2])
            end
         end
      end
   end
end

local _finish = function(self, body, headers, statusCode)
   local client = self.socket
   local parser = self.parser
   local keepAlive = self.should_keep_alive

   local statusCode = statusCode or 200
   local reasonPhrase = http_codes[statusCode]

   if type(body) == 'table' then
      body = table.concat(body)
   end
   local length = #body

   local head = {
      string.format('HTTP/1.1 %s %s\r\n', statusCode, reasonPhrase)
   }
   headers = headers or {['Content-Type']='text/plain'}
   headers['Date'] = os.date('!%a, %d %b %Y %H:%M:%S GMT')
   headers['Server'] = 'ASyNC'
   if not (headers['Transfer-Encoding']
      and headers['Transfer-Encoding'] == 'chunked') then
      headers['Content-Length'] = length
   end

   for key, value in pairs(headers) do
      if type(key) == 'number' then
         table.insert(head, value)
         table.insert(head, '\r\n')
      else
         local entry = string.format('%s: %s\r\n', key, value)
         table.insert(head, entry)
      end
   end

   table.insert(head, '\r\n')
   table.insert(head, body)
   client.write(table.concat(head))

   if keepAlive then
      parser:reinitialize('request')
      parser:finish()
   else
      parser:finish()
      client.close()
   end
end

return function(req)
   _getcookies(req)
   _getform(req)
   req.finish = _finish
   return req
end
