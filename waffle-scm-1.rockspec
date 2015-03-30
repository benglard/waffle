package = "waffle"
version = "scm-1"

source = {
   url = "git://github.com/benglard/waffle",
   dir = "waffle"
}

description = {
   summary = "A tiny, fast, asynchronous web framework for Lua/Torch",
   detailed = [[
        A tiny, fast, asynchronous web framework for Lua/Torch.
   ]],
   homepage = "https://github.com/benglard/waffle"
}

dependencies = {
   "torch >= 7.0",
   "async >= 1"
}

build = {
   type = "command",
   build_command = [[
cmake -E make_directory build;
cd build;
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(LUA_BINDIR)/.." -DCMAKE_INSTALL_PREFIX="$(PREFIX)"; 
$(MAKE)
   ]],
   install_command = "cd build && $(MAKE) install"
}