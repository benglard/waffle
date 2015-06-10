local Cache = require 'waffle.cache'
local redis = require 'redis-async'

local session = {}
session.type = ''

session.new = function(self, stype, args)
   assert(self.data == nil, 'Only one session allowed per application')
   stype = stype or 'cache'
   args = args or {}
   if stype == 'cache' then
      local size = args.size or 1000
      self.data = Cache(size)
   elseif stype == 'redis' then
      self.prefix = args.prefix or 'waffle-'
      local host = args.redishost or args.host or '127.0.0.1'
      local port = args.redisport or args.port or '6379'
      redis.connect({host=host, port=port}, function(client)
         self.data = client
      end)
      print(string.format('Redis client listening on %s:%s', host, port))
   else
      error('unsupported session type')
   end
   self.type = stype
end

session.get = function(self, name, cb)
   if self.type == 'cache' then
      return self.data:get(name)
   else
      local fname = self.prefix .. name
      self.data.get(fname, function(data)
         cb(data)
      end)
   end
end

session.set = function(self, name, value)
   if self.type == 'cache' then
      self.data:push(name, value)
   else
      local fname = self.prefix .. name
      self.data.set(fname, value, function(data)
         assert(data.status == 'OK', 'Error writing to redis')
      end)
   end
end

session.delete = function(self, name)
   if self.type == 'cache' then
      self.data:delete(name)
   else
      local fname = self.prefix .. name
      self.data.del(fname, function(data)
         assert(data == 1, 'Error deleting redis key')
      end)
   end
end

local mt = {
   __call = session.new,
   __index = function(self, key)
      if key == 'data' then
         return rawget(session, key)
      else
         return session:get(key)
      end
   end,
   __newindex = function(self, key, val)
      if key == 'data' or key == 'type' or key == 'prefix' then
         rawset(session, key, val)
      else
         session:set(key, val)
      end
   end
}

return setmetatable(session, mt)