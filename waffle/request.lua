local async = require 'async'
local encodings = require 'waffle.encodings'
local afs = async.fs

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

local _getform = function(self)
   self.form = {}
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
                  save = _save
               }
            end
         end
      else
         -- URL Encoded
         for param in string.gsplit(rbody, '&') do
            local arg = string.split(param, '=')
            self.form[arg[1]] = encodings.urldecode(arg[2])
         end
      end
   end
end

return function(req)
   _getcookies(req)
   _getform(req)
   return req
end