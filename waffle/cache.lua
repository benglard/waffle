local utils = require 'waffle.utils'
local table = require 'waffle.table'
local cache = {}

local _push = function(cache, key, value)
   utils.stringassert(key)
   if #cache.keys == cache.size then cache.pop(1) end
   cache.store[key] = value
   if not(table.contains(cache.keys, key)) then
      table.insert(cache.keys, key)
   end
end

local _pop = function(cache, index)
   local index = index or #cache.keys
   local victim = table.remove(cache.keys, index)
   if victim ~= nil then
      cache.store[victim] = nil
   end
   return victim
end

local _get = function(cache, key)
   return cache.store[key]
end

local _empty = function(cache)
   return #cache.keys == 0
end

local _clean = function(cache)
   cache.store = {}
   cache.keys = {}
end

return function(size)
   local rv = {}
   rv.size = size or 10
   rv.store = {}
   rv.keys = {}
   rv.push = function(key, value) _push(rv, key, value) end
   rv.pop = function(index) return _pop(rv, index) end
   rv.get = function(key) return _get(rv, key) end
   rv.empty = function() return _empty(rv) end
   rv.clean = function() _clean(rv) end
   setmetatable(rv, {
      __index = function(_, k) return _get(rv, k) end,
      __newindex = function(_, k, v) _push(rv, k, v) end
   })
   return rv
end
