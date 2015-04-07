local utils = require 'waffle.utils'

local _push = function(cache, key, value)
   utils.stringassert(key)
   if #cache.keys == cache.size then _pop(cache, 1) end
   if cache.store[key] == nil then
      table.insert(cache.keys, key)
   end
   cache.store[key] = value
end

local _pop = function(cache, index)
   local index = index or #cache.keys
   local victim = table.remove(cache.keys, index)
   if victim ~= nil then
      cache.store[victim] = nil
   end
   return victim
end

return function(size)
   local rv = {}
   rv.size = size or 10
   rv.store = {}
   rv.keys = {}
   rv.push = function(key, value) _push(rv, key, value) end
   rv.pop = function(index) return _pop(rv, index) end
   rv.get = function(key) return rv.store[key] end
   rv.empty = function() return #rv.keys == 0 end
   rv.clean = function()
      rv.store = {}
      rv.keys = {}
   end
   setmetatable(rv, {
      __index = function(_, k) return rv.store[k] end,
      __newindex = function(_, k, v) _push(rv, k, v) end
   })
   return rv
end