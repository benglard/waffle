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

return string