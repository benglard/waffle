local async = require 'async'
local response = require 'waffle.response'
local paths = require 'waffle.paths'
local string = require 'waffle.string'
local utils = require 'waffle.utils'
local Cache = require 'waffle.cache'

local app = {}
app.viewFuncs = {}
app.errorFuncs = {}
app.properties = Cache(100)
app.urlCache = Cache(20)

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
   elseif field == 'cachesize' then
      app.urlCache.size = value
   end
end

local _handle = function(request, handler)
   local function getcookies()
      request.cookies = {}
      if request.headers.cookie then
         for param in string.gsplit(request.headers.cookie, '; ') do
            local arg = string.split(param, '=')
            request.cookies[arg[1]] = arg[2]
         end
      end
   end

   local url = request.url.path
   local method = request.method
   local fullURL
   if string.sub(url, -1) == '/' then
      fullURL = request.method .. url .. (request.url.query or '')
   else
      fullURL = request.method .. url .. '/' .. (request.url.query or '')
   end

   local cache = app.urlCache[fullURL]
   if cache ~= nil then
      if app.autocache and cache.response.body ~= '' then
         response.load(cache.response, response.resend, handler)
      else
         response.new(handler)
         request.params = cache.match
         request.url.args = cache.args
         getcookies()
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
         getcookies()

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
               if app.debug then print(err) end
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
   local host = options.host or '127.0.0.1'
   local port = options.port or '8080'
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
      res.send(string.format(
[[<html>
<head></head>
<body><h1>Error: %d</h1><p>%s</p></body>
</html>]], errorCode, async.http.codes[errorCode]))
   end
end

app.repl = function(options)
   local options = options or {}
   local host = options.host or '127.0.0.1'
   local port = options.port or '8081'
   async.repl.listen({host=host, port=port})
   print(string.format('REPL listening on %s:%s', host, port))
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