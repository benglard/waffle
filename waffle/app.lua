local async = require 'async'
local utils = require 'waffle.utils'
local paths = require 'waffle.paths'
string.gsplit = utils.iterator(string.split)

local response  = require 'waffle.response'
local wrequest  = require 'waffle.request'
local Cache     = require 'waffle.cache'
local Session   = require 'waffle.session'
local WebSocket = require 'waffle.websocket'

local app = {}
app.viewFuncs  = {}
app.errorFuncs = {}
app.properties = Cache(100)
app.urlCache   = Cache(20)
app.session    = Session

app.set = function(field, value)
   app.properties[field] = value

   if field == 'public' then
      for file in paths.gwalk(value) do
         local route = file
         if string.sub(file, 1, 1) == '.' then
            route = string.sub(file, 2)
         end
         app.get(route, function(req, res)
            res.sendFile(file)
         end)
      end
   elseif field == 'templates' then
      response.templates = value
   elseif field == 'cachesize' then
      app.urlCache.size = value
   end
end

local _handle = function(request, handler)
   local url = request.url.path
   local method = request.method
   local delim = ''
   if string.sub(url, -1) ~= '/' then delim = '/' end
   local query = request.url.query or ''
   local fullURL = string.format('%s%s%s%s',
      request.method, url, delim, query)
   request.fullurl = fullURL

   if app.print then
      print('Request from ' .. fullURL)
   end

   local cache = app.urlCache[fullURL]
   if cache ~= nil then
      if app.autocache and cache.response.body ~= '' then
         response.load(cache.response, response.resend, handler)
      else
         response.new(handler)
         request.params = cache.match
         request.url.args = cache.args
         wrequest(request)
         cache.cb(request, response)
      end
      return nil
   end

   response.new(handler)

   for pattern, funcs in pairs(app.viewFuncs) do
      local match = {string.match(url, pattern)}
      local b1 = #match > 0
      local b2 = match[1] == '/'
      local b3 = url == '/'

      if b1 and (not(b2) or b3) then
         request.params = match
         request.url.args = {}
         if request.url.query then
            for param in string.gsplit(request.url.query, '&') do
               local arg = string.split(param, '=')
               request.url.args[arg[1]] = arg[2]
            end
         end
         wrequest(request)

         if funcs[method] then
            local ok, err = pcall(funcs[method], request, response)
            if ok then
               local data = {
                  match = match,
                  args = request.url.args,
                  cb = funcs[method]
               }
               if app.autocache then
                  data.response = response.save()
               end
               app.urlCache[fullURL] = data
            else
               if app.debug then
                  print('ERROR: ' .. err)
               end
               app.abort(500, err, request, response)
            end
         else
            app.abort(403, 'Forbidden', request, response)
         end

         return nil
      end
   end

   app.abort(404, 'Not Found', request, response)
end

app.listen = function(options)
   local options = options or {}
   local host = options.host or app.host or '127.0.0.1'
   local port = options.port or app.port or '8080'
   async.http.listen({host=host, port=port}, _handle)
   print(string.format('Listening on %s:%s', host, port))
   async.go()
end

app.serve = function(url, method, cb)
   utils.stringassert(url)
   utils.stringassert(method)
   assert(cb ~= nil)

   if app.viewFuncs[url] == nil then
      app.viewFuncs[url] = {}
   end
   app.viewFuncs[url][method] = cb
end

app.get = function(url, cb) app.serve(url, 'GET', cb)
end

app.post = function(url, cb) app.serve(url, 'POST', cb)
end

app.put = function(url, cb) app.serve(url, 'PUT', cb)
end

app.delete = function(url, cb) app.serve(url, 'DELETE', cb)
end

app.ws = {
   defined = false,
   clients = WebSocket.clients
}

app.ws.serve = function(url, cb)
   if not app.ws.defined then
      async.http.listen = WebSocket.listen
      app.ws.defined = true
   end
   app.get(url, function(req, res)
      local ws = WebSocket(req, res)
      local ok, err = pcall(cb, ws) -- implement ws methods
      ok, err = ws:open()
      if not ok then
         app.abort(500, err, req, res)
         return nil
      end
   end)
end

setmetatable(app.ws, {
   __call = function(self, url, cb)
      app.ws.serve(url, cb)
   end
})

app.error = function(errorCode, cb)
   assert(errorCode ~= nil and async.http.codes[errorCode] ~= nil)
   assert(cb ~= nil)
   app.errorFuncs[errorCode] = cb
end

app.abort = function(errorCode, description, req, res)
   if app.errorFuncs[errorCode] ~= nil then
      app.errorFuncs[errorCode](description, req, res)
      return nil
   else
      res.setStatus(errorCode)
      res.setHeader('Content-Type', 'text/html')
      res.send(html { body {
         h1 'Error: ${code}' % { code = errorCode },
         p(async.http.codes[errorCode]),
         p(description) 
      }})
   end
end

app.repl = function(options)
   local options = options or {}
   local host = options.host or app.replhost or '127.0.0.1'
   local port = options.port or app.replport or '8081'
   async.repl.listen({host=host, port=port})
   print(string.format('REPL listening on %s:%s', host, port))
end

app.CmdLine = function(args)
   local cmd = torch.CmdLine()
   cmd:text()
   cmd:text('Waffle Command Line')
   cmd:text()
   cmd:text('Options:')
   cmd:option('--host', '127.0.0.1', 'Host IP on which to recieve requests')
   cmd:option('--port', '8080', 'Host Port on which to recieve requests')
   cmd:option('--debug', false, 'Set application to debugging mode if true')
   cmd:option('--public', './public', 'Set application public folder')
   cmd:option('--templates', './templates', 'Set application public folder')
   cmd:option('--replhost', '127.0.0.1', 'Host IP on which to recieve REPL requests')
   cmd:option('--replport', '8081', 'Host Port on which to recieve REPL requests')
   cmd:option('--print', false, 'Print the method and url of every request if true')
   cmd:option('--session', 'cache', 'Type of session: cache | redis')
   cmd:option('--sessionsize', 1000, 'Size of session (only valid for cached sessions)')
   cmd:option('--redishost', '127.0.0.1', 'Redis host (only valid for redis sessions)')
   cmd:option('--redisport', '6379', 'Redis port (only valid for redis sessions)')
   cmd:option('--redisprefix', 'waffle-', 'Redis key prefix (only valid for redis sessions)')
   cmd:option('--cachesize', 20, 'Size of URL cache')
   cmd:option('--autocache', false, 'Automatically cache response body, headers, and status code if true')
   cmd:text()
   local opt = cmd:parse(args or arg or {})
   app.session(opt.session, opt)
   return app(opt)
end

setmetatable(app, {
   __call = function(self, options)
      options = options or {}
      for k, v in pairs(options) do
         app.set(k, v)
      end
      return app
   end,
   __index = function(self, idx)
      return app.properties[idx]
   end
})

return app