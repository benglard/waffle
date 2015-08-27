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
      local idx = 0
      local rbody = self.body
      local lrb = #rbody

      while idx < lrb do
         -- Multipart form encoded
         local inner = string.find(rbody, 'Content-', idx)
         if inner == nil then break end
         local rest = rbody:sub(inner)
         idx = inner + 1

         inner = string.find(rbody, '\r', inner)
         rest = rbody:sub(idx, inner - 1):gsub('"', '')
         
         local data = string.split(rest, ';')
         local nd = #data
         local isfile = nd > 2
         local name = ''

         if isfile then
            name = data[2]:gsub(' ', ''):split('=')[2]
            local fname = data[3]:gsub(' ', ''):split('=')[2]

            -- Find content-type
            idx = inner
            inner = string.find(rbody, '\r', idx + 1)
            rest = rbody:sub(idx, inner - 1)
            local ctype = rest:split(':')[2]:gsub(' ', '')
            local binary = ctype:find('text') == nil

            self.form[name] = {
               filename = fname,
               type = ctype,
               binary = binary
            }

            idx = inner
         else
            name = data[2]:gsub(' ', ''):split('=')[2]
            self.form[name] = ''
         end

         inner = inner + 4

         local inner2 = string.find(rbody, 'FormBoundary', inner) - 1
         while inner2 > 1 do
            inner2 = inner2 - 1
            local c = rbody:sub(inner2, inner2 + 1)
            if string.byte(c) == 13 then break end
         end
         rest = rbody:sub(inner, inner2 - 1)

         if isfile then
            self.form[name].save = _save
            self.form[name].data = rest
         else
            self.form[name] = rest
         end

         idx = inner2
      end

      if idx == 0 then -- URL encoded
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