package = "waffle"
version = "scm-1"

source = {
   url = "git://github.com/benglard/waffle",
}

description = {
   summary = "A tiny, fast, asynchronous web framework for Lua/Torch",
   detailed = [[A tiny, fast, asynchronous web framework for Lua/Torch]],
   homepage = "https://github.com/benglard/waffle"
}

dependencies = {
   "torch >= 7.0",
   "async"
}

build = {
   type = "builtin",
   modules = {
      ['waffle.init'] = 'waffle/init.lua'
   }
}