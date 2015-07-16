-- package
local ok, html = pcall(require, 'htmlua')
local msg = [[
Please first install htmlua to handle html templating.
Assuming luarocks, install htmlua like so:
> (sudo) luarocks install https://raw.githubusercontent.com/benglard/htmlua/master/htmlua-scm-1.rockspec]]   

if not ok then
   print(msg)
   os.exit()
else
   _G.html = html
end 
return require('waffle.app')