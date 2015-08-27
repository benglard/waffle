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
   type = 'command',
   build_command = '$(MAKE) LUA_BINDIR=$(LUA_BINDIR)  LUA_LIBDIR=$(LUA_LIBDIR)  LUA_INCDIR=$(LUA_INCDIR)',
   install_command = 'cp -r waffle $(LUADIR)',
   install = { bin = { 'wafflemaker' } }
}