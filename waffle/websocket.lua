--[[
Some websocket code based on:
https://github.com/openresty/lua-resty-websocket/
Thank you very much @agentzh
]]

local encodings = require 'waffle.encodings'
local bit = require 'bit'

local async = require 'async'
local tcp = require 'async.tcp'
local newHttpParser = require 'lhttp_parser'.new
local parseUrl = require 'lhttp_parser'.parseUrl

local WebSocket = {}
WebSocket.clients = {}

local magic = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
local http = async.http
local byte = string.byte
local char = string.char
local sub = string.sub
local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local lshift = bit.lshift
local rshift = bit.rshift
local concat = table.concat
local rand = math.random

local types = {
   [0x0] = 'continuation',
   [0x1] = 'text',
   [0x2] = 'binary',
   [0x8] = 'close',
   [0x9] = 'ping',
   [0xa] = 'pong',
}

local StringPointer = function(s)
   local self = { p = 1, s = s }
   self.receive = function(_, n)
      local p = self.p
      local c = p + n
      local rv = sub(s, p, c - 1)
      self.p = c
      return rv
   end
   return self
end

local _recv_frame = function(frame, maxlen, forcemask)
   -- Returns GOOD, MSG, TYPE, CODE
   maxlen = maxlen or 65535
   if forcemask == nil then forcemask = true end

   local data, err = frame:receive(2)
   if not data then
      return false, 'failed to receive the first 2 bytes: ' .. err
   end

   local fst, snd = byte(data, 1, 2)
   local fin = band(fst, 0x80) ~= 0

   if band(fst, 0x70) ~= 0 then
      return false, 'bad RSV1, RSV2, or RSV3 bits'
   end

   local opcode = band(fst, 0x0f)
   if opcode >= 0x3 and opcode <= 0x7 then
      return false, 'reserved non-control frames'
   end

   if opcode >= 0xb and opcode <= 0xf then
      return false, 'reserved control frames'
   end

   local mask = band(snd, 0x80) ~= 0
   if forcemask and not mask then
      return false, 'frame unmasked'
   end

   local payloadlen = band(snd, 0x7f)

   if payloadlen == 126 then
      local data, err = frame:receive(2)
      if not data then
         return false, 'failed to receive the 2 byte payload length: ' .. err
      end
      payloadlen = bor(lshift(byte(data, 1), 8), byte(data, 2))
   elseif payload_len == 127 then
      local data, err = frame:receive(8)
      if not data then
         return false, 'failed to receive the 8 byte payload length: ' .. err
      end

      if byte(data, 1) ~= 0 or byte(data, 2) ~= 0 or
         byte(data, 3) ~= 0 or byte(data, 4) ~= 0 then
         return false, 'payload len too large'
      end

      local fifth = byte(data, 5)
      if band(fifth, 0x80) ~= 0 then
         return false, 'payload len too large'
      end

      payloadlen = bor(
         lshift(fifth, 24),
         lshift(byte(data, 6), 16),
         lshift(byte(data, 7), 8),
         byte(data, 8))
   end

   if band(opcode, 0x8) ~= 0 then -- control frame
      if payloadlen > 125 then
         return false, 'too long payload for control frame'
      end
      if not fin then
         return false, 'fragmented control frame'
      end
   end

   if payloadlen > maxlen then
      return false, 'exceeding max payload len'
   end

   local rest = payloadlen
   if mask then rest = rest + 4
   end

   local data = ''
   if rest > 0 then
      data, err = frame:receive(rest)
      if not data then
         return false, 'failed to read masking-len and payload: ' .. err
      end
   end

   if opcode == 0x8 then -- close frame
      if payloadlen > 0 then
         if payloadlen < 2 then
            return 
               false, 'close frame with a body must carry a 2-byte status code'
         end

         local msg = ''
         local code
         if mask then
            local fst = bxor(byte(data, 4 + 1), byte(data, 1))
            local snd = bxor(byte(data, 4 + 2), byte(data, 2))
            code = bor(lshift(fst, 8), snd)

            if payloadlen > 2 then
               local bytes = {}
               for i = 3, payloadlen do
                  bytes[i - 2] = char(bxor(
                     byte(data, 4 + i),
                     byte(data, (i - 1) % 4 + 1)))
               end
               msg = concat(bytes)
            end
         else
            local fst = byte(data, 1)
            local snd = byte(data, 2)
            code = bor(lshift(fst, 8), snd)
            if payloadlen > 2 then
               msg = sub(data, 3)
            end
         end

         return true, msg, 'close', code
      end

      return true, '', 'close', nil
   end

   local msg
   if mask then
      local bytes = {}
      for i = 1, payloadlen do
      bytes[i] = char(bxor(
         byte(data, 4 + i),
         byte(data, (i - 1) % 4 + 1)))
      end
      msg = concat(bytes)
   else
      msg = data
   end

   return true, msg, types[opcode], not fin and 'again' or nil
end

local _build_frame = function(fin, opcode, payloadlen, payload, masking)
   local fst = opcode
   if fin then fst = bor(0x80, opcode)
   end

   local snd, extra_len_bytes
   if payloadlen <= 125 then
      snd = payloadlen
      extra_len_bytes = ''
   elseif payloadlen <= 65535 then
      snd = 126
      extra_len_bytes = char(
         band(rshift(payloadlen, 8), 0xff),
         band(payloadlen, 0xff))
   else
      if band(payloadlen, 0x7fffffff) < payloadlen then
         return false, 'payload too big'
      end

      snd = 127
      -- only support 31-bit length here
      extra_len_bytes = char(
         0, 0, 0, 0, band(rshift(payloadlen, 24), 0xff),
         band(rshift(payloadlen, 16), 0xff),
         band(rshift(payloadlen, 8), 0xff),
         band(payloadlen, 0xff))
   end

   local masking_key
   if masking then
      -- set the mask bit
      snd = bor(snd, 0x80)
      local key = rand(0xffffffff)
      masking_key = char(
         band(rshift(key, 24), 0xff),
         band(rshift(key, 16), 0xff),
         band(rshift(key, 8), 0xff),
         band(key, 0xff))

      local bytes = {}
      for i = 1, payloadlen do
         bytes[i] = char(
            bxor(byte(payload, i),
            byte(masking_key, (i - 1) % 4 + 1)))
      end
      payload = concat(bytes)
   else
     masking_key = ''
   end

   return char(fst, snd) .. extra_len_bytes .. masking_key .. payload
end

local _send_frame = function(ws, fin, opcode, payload, maxlen, mask)
   maxlen = maxlen or 65535
   mask = mask or false

   if not payload then
      payload = ''
   elseif type(payload) ~= 'string' then
      payload = tostring(payload)
   end

   local payloadlen = #payload
   if payloadlen > maxlen then
      return false, 'payload too big'
   end

   if band(opcode, 0x8) ~= 0 then -- control frame
      if payloadlen > 125 then
         return false, 'too much payload for control frame'
      end
      if not fin then
         return false, 'fragmented control frame'
      end
   end

   local frame, err = _build_frame(fin, opcode, payloadlen, payload, mask)
   if not frame or err ~= nil then
      return false, 'failed to build frame: ' .. err
   end

   ws.request.socket.write(frame)
end

local _open = function(self)
   self.opened = true
   local req = self.request
   local res = self.response

   local status = true
   local err = ''

   if req.headers['upgrade'] ~= 'websocket' then
      status = false
      err = 'Can Upgrade only to WebSocket'
   end

   local origin = req.headers.origin or req.headers['sec-websocket-origin']
   if not self.checkorigin(origin) then
      status = false
      err = 'Cross origin websockets not allowed'
   end

   local key = string.format('%s%s', req.headers['sec-websocket-key'], magic)
   local b64 = encodings.sha1b64(key)

   local protocols = req.headers['sec-websocket-protocol']
   local useproto = protocols ~= nil
   if useproto then
      local proto = protocols:split(',')[1]
      res.header('Sec-WebSocket-Protocol', proto)
   end

   res.header('upgrade', 'websocket')
      .header('connection', 'upgrade')
      .header('Sec-WebSocket-Accept', b64)

   if status then
      res.status(101).send('')
   else
      res.status(403).send(err)
      self.opened = false
      return status, err
   end

   req.socket.ondata(function(data)
      local ok, good, msg, dtype, code = pcall(_recv_frame, StringPointer(data))
      if ok and good then
         local rv = {
            data = msg,
            type = dtype,
            code = code
         }
         if dtype == 'close' then
            self:close()
         elseif dtype == 'pong' then
            self.onpong(rv)
         else
            self.onmessage(rv)
         end
      else self:close(code or 1002, msg)
      end
   end)

   return pcall(self.onopen, self.req)
end

local _write = function(self, data, binary)
   if not self.opened then return false, 'WebSocket not opened' end
   data = data or ''
   binary = binary or false
   local opcode = 0x1
   if binary then opcode = 0x2 end
   return pcall(_send_frame, self, true, opcode, data)
end

local _ping = function(self, data)
   if not self.opened then return false, 'WebSocket not opened' end
   return pcall(_send_frame, self, true, 0x9, data)
end

local _close = function(self, code, msg)
   if not self.opened then return false, 'WebSocket not opened' end
   self.opened = false
   local ok, err = pcall(self.onclose, self.req)
   if ok then
      local payload
      if code then
         if type(code) ~= 'number' or code > 0x7fff then end
         payload = char(
            band(rshift(code, 8), 0xff), 
            band(code, 0xff)) .. (msg or '')
      end
      ok, err = pcall(_send_frame, self, true, 0x8, payload)
      self.request.socket.close()

      local clients = WebSocket.clients[self.request.url.path]
      for i = 1, #clients do
         if clients[i] == self then
            clients[i] = nil
         end
      end

      return ok, err
   end
   return ok, err
end

WebSocket.new = function(req, res)
   local rv = {
      request  = req,
      response = res,
      opened   = false,
      
      checkorigin = function(o) return true end,
      onopen    = function(r) end,
      onmessage = function(d) end,
      onpong    = function(d) end,
      onclose   = function(r) end,
      
      open  = _open,
      write = _write,
      ping  = _ping,
      close = _close,
   }

   local clients = WebSocket.clients[req.url.path]
   if clients == nil then
      WebSocket.clients[req.url.path] = {rv}
   else
      local nc = #clients
      WebSocket.clients[req.url.path][nc + 1] = rv
   end
   return rv
end

WebSocket.listen = function(domain, handler)
   tcp.listen(domain, function(client)
      -- Http Request Parser:
      local currentField, headers, lurl, request, parser, keepAlive, body
      body = {}
      parser = newHttpParser('request', {
         onMessageBegin = function()
            headers = {}
         end,
         onUrl = function(value)
            lurl = parseUrl(value)
         end,
         onHeaderField = function(field)
            currentField = field
         end,
         onHeaderValue = function(value)
            local cf = currentField:lower()
            headers[cf] = value
         end,
         onHeadersComplete = function(info)
            request = info
            if request.should_keep_alive then    
               headers['Content-Length'] = #body
               if info.version_minor < 1 then -- HTTP/1.0: insert Connection: keep-alive
                  headers['connection'] = 'keep-alive'
               end
            else
               if info.version_minor >= 1 then -- HTTP/1.1+: insert Connection: close for last msg
                  headers['connection'] = 'close'
               end
            end
         end,
         onBody = function(chunk)
            table.insert(body, chunk)
         end,
         onMessageComplete = function()
            request.body = table.concat(body)
            request.url = lurl
            request.headers = headers
            request.parser = parser
            request.socket = client
            keepAlive = request.should_keep_alive

            if request.method == 'POST' and 
               request.headers['content-type'] == 'application/json' then
               local ok, j = pcall(json.decode, request.body)
               if ok then request.body = j end
            end

            handler(request, function(body, headers, statusCode)
               -- Code:
               local statusCode = statusCode or 200
               local reasonPhrase = http.codes[statusCode]
               
               -- Body length:
               if type(body) == 'table' then
                  body = table.concat(body)
               end
               local length = #body

               -- Header:
               local head = {
                  string.format('HTTP/1.1 %s %s\r\n', statusCode, reasonPhrase)
               }
               headers = headers or {['Content-Type'] = 'text/plain'}
               headers['Date'] = os.date("!%a, %d %b %Y %H:%M:%S GMT")
               headers['Server'] = 'ASyNC'
               headers['Content-Length'] = length

               for key, value in pairs(headers) do
                  if type(key) == 'number' then
                     table.insert(head, value)
                     table.insert(head, '\r\n')
                  else
                     table.insert(head, string.format('%s: %s\r\n', key, value))
                  end
               end

               -- Write:
               table.insert(head, '\r\n')
               table.insert(head, body)
               client.write(table.concat(head))

               -- Keep alive?
               if keepAlive then
                  parser:reinitialize('request')
                  parser:finish()
               else
                  parser:finish()
                  client.close()
               end
            end)
         end
      })

      -- Pipe data into parser:
      client.ondata(function(chunk)
         -- parse chunk:
         parser:execute(chunk, 0, #chunk)
      end)
   end)
end

return setmetatable(WebSocket, {
   __call = function(self, req, res)
      return WebSocket.new(req, res)
   end
})