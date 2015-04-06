local string = require 'string'
local utils = require 'waffle.utils'

string.split = function(text, pattern)
   utils.stringassert(text)
   utils.stringassert(pattern)
   local start = 1
   local patStart, patEnd = string.find(text, pattern, 1)
   local results = {}
   while patStart do
      table.insert(results, string.sub(text, start, patStart - 1))
      start = patEnd + 1
      patStart, patEnd = string.find(text, pattern, start)
   end
   table.insert(results, string.sub(text, start))
   return results
end

string.gsplit = utils.iterator(string.split)

getmetatable('').__mod = function(str, tab)
   -- http://lua-users.org/wiki/StringInterpolation
   -- ex: print('${name} is ${value}' % {name='foo', value='bar'})
   return (str:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

return string