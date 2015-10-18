local utils = require 'waffle.utils'
local ffi = require 'ffi'
local path = debug.getinfo(1).source:sub(2)
local libpath = paths.concat(path:match('(.*/)'), 'libwaffle.so')
local libwaffle = ffi.load(libpath)
ffi.cdef 'void sha1b64(const char* src, char* dest);'

local encodings = {}

encodings.sha1b64 = function(key)
   utils.stringassert(key)
   local dest = ffi.new('char[28]')
   libwaffle.sha1b64(key, dest)
   return ffi.string(dest)
end

local _hex2char = function(x)
   return string.char(tonumber(x, 16))
end

encodings.urldecode = function(url)
   url = url or ''
   local rv, _ = url:gsub('%%(%x%x)', _hex2char):gsub('+', ' ')
   return rv
end

encodings.uuid4 = function()
   local rv = {}
   local rand = math.random
   local format = string.format

   local map = { '8', '9', 'a', 'b' }
   local y = map[rand(1, 4)]

   rv[1] = format('%08x', rand(0, 4294967295))       -- 2**32 - 1
   rv[2] = format('%04x', rand(0, 65535))            -- 2**16 - 1
   rv[3] = format('4%03x', rand(0, 4095))            -- 2**12 - 1
   rv[4] = format('%s%03x', y, rand(0, 4095))        -- 2**12 - 1
   rv[5] = format('%012x', rand(0, 281474976710656)) -- 2**48 - 1

   return table.concat(rv, '-')
end

return encodings