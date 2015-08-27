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

return encodings