local encodings = require 'waffle.encodings'
local redis = require 'redis-async'

local _SERIALIZE = torch.serialize
local _DESERIALIZE = torch.deserialize
local _OPEN = '__open__'
local _WRITECB = function(data)
   if type(data) == 'table' and data.status ~= 'OK' then
      assert(data.error == nil, data.error[2])
   end
end

local session = {
   defined = false,
   type = '',
   request = nil,
   response = nil
}

session.new = function(self, stype, args)
   assert(self.data == nil, 'Only one session allowed per application')
   stype = stype or 'memory'
   args = args or {}
   if stype == 'memory' then
      self.data = {}
   elseif stype == 'redis' then
      self.prefix = args.prefix or 'waffle'
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
   self.defined = true
end

session.start = function(self, req, res)
   if self.defined then
      self.request = req
      self.response = res
   end
end

session.sessionid = function(self)
   local cookie = self.request.cookies.sid
   if cookie == nil then
      cookie = encodings.uuid4()
      self.response.cookie('sid', cookie)
   end
   return cookie
end

session.rediskey = function(self)
   local temp = '%s:%s'
   local sid = self:sessionid()
   return string.format(temp, self.prefix, sid)
end

session.getrediskeys = function(self, cb)
   local pattern = string.format('%s:*', self.prefix)
   self.data.keys(pattern, function(keys)
      local keyset = {}
      for idx, key in pairs(keys) do
         keyset[key] = true
      end
      cb(keyset)
   end)
end

session.get = function(self, name, cb, default)
   if self.type == 'memory' then
      local sid = self:sessionid()
      local db = self.data[sid]
      if db == nil then
         self.data[sid] = {}
      else
         return db[name]
      end
   else
      local sid = self:rediskey()
      session:getrediskeys(function(keys)
         if keys[sid] then
            self.data.hget(sid, name, function(value)
               if value == nil then
                  value = default
               else
                  value = _DESERIALIZE(value)
               end
               cb(value)
            end)
         else
            self.data.hmset(sid, _OPEN, 1, _WRITECB)
            cb(default)
         end
      end)
   end
end

session.set = function(self, name, value)
   if self.type == 'memory' then
      local sid = self:sessionid()
      local db = self.data[sid]
      if db == nil then
         self.data[sid] = {}
      end
      self.data[sid][name] = value
   else
      local sid = self:rediskey()
      value = _SERIALIZE(value)
      session:getrediskeys(function(keys)
         if keys[sid] then
            self.data.hset(sid, name, value, _WRITECB)
         else
            self.data.hmset(sid, name, value, _WRITECB)
         end
      end)
   end
end

session.delete = function(self, name)
   if self.type == 'memory' then
      local sid = self:sessionid()
      local db = self.data[sid]
      if db == nil then
         self.data[sid] = {}
      else
         self.data[sid][name] = nil
      end
   else
      local sid = self:rediskey()
      session:getrediskeys(function(keys)
         if keys[sid] then
            self.data.hdel(sid, name, _WRITECB)
         else
            self.data.hmset(sid, _OPEN, 1, _WRITECB)
         end
      end)
   end
end

session.flush = function(self)
   if self.type == 'memory' then
      local sid = self:sessionid()
      self.data[sid] = nil
   else
      local sid = self:rediskey()
      session:getrediskeys(function(keys)
         if keys[sid] then
            self.data.del(sid, _WRITECB)
         end
      end)
   end
end

local mt = {
   __call = session.new,
   __index = function(self, key)
      if key == 'data' or key == 'type' then
         return rawget(session, key)
      else
         return session:get(key)
      end
   end,
   __newindex = function(self, key, val)
      if key == 'defined' or key == 'type' or
         key == 'request' or key == 'response' or
         key == 'data' or key == 'prefix' then
         rawset(session, key, val)
      else
         session:set(key, val)
      end
   end
}

return setmetatable(session, mt)