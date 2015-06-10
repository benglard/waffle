package = 'waffle'
version = 'scm-1'

source = {
   url = 'git://github.com/benglard/waffle',
}

description = {
   summary = 'Fast, asynchronous web framework for Lua/Torch',
   detailed = [[Waffle is a fast, asynchronous, express-inspired web framework for Lua/Torch]],
   homepage = 'https://github.com/benglard/waffle'
}

dependencies = {
   'torch >= 7.0',
   'paths >= 1.0',
   'buffer',
   'async',
   'redis-async'
}

build = {
   type = 'builtin',
   modules = {
      ['waffle.init'] = 'waffle/init.lua',
      ['waffle.app'] = 'waffle/app.lua',
      ['waffle.cache'] = 'waffle/cache.lua',
      ['waffle.paths'] = 'waffle/paths.lua',
      ['waffle.response'] = 'waffle/response.lua',
      ['waffle.session'] = 'waffle/session.lua',
      ['waffle.string'] = 'waffle/string.lua',
      ['waffle.utils'] = 'waffle/utils.lua'
   },
   install = {
      bin = {
         'wafflemaker'
      }
   }
}