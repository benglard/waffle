local utils = require 'waffle.utils'

local _push = function(cache, key, value)
   utils.stringassert(key)
   if cache.full() then
      cache:pop(1)
   end
   if cache.store[key] == nil then
      table.insert(cache.keys, key)
   end
   cache.store[key] = value
end

local _get = function(cache, key)
   return cache.store[key]
end

local _pop = function(cache, index)
   local index = index or #cache.keys
   local victim = table.remove(cache.keys, index)
   if victim ~= nil then
      cache.store[victim] = nil
   end
   return victim
end

local _del = function(cache, key)
   for idx, name in pairs(cache.keys) do
      if name == key then
         cache:pop(idx)
         return true
      end
   end
   return false
end

local mt = {
   __index = _get,
   __newindex = _push
}

return function(size)
   local rv  = {}
   rv.size   = size or 10
   rv.store  = {}
   rv.keys   = {}
   rv.get    = _get
   rv.push   = _push
   rv.pop    = _pop
   rv.delete = _del
   rv.full   = function() return #rv.keys == rv.size end
   rv.empty  = function() return #rv.keys == 0 end
   rv.clean  = function()
      rv.store = {}
      rv.keys = {}
   end
   return setmetatable(rv, mt)
end