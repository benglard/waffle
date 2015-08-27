-- package
require 'xlua'

local ok, html = pcall(require, 'htmlua')
local msg = [[
Please first install htmlua to handle html templating.
Assuming luarocks, install htmlua like so:
> (sudo) luarocks install https://raw.githubusercontent.com/benglard/htmlua/master/htmlua-scm-1.rockspec]]   

if not ok then
   print(msg)
   os.exit()
else
   for key, val in pairs(html) do
      if key ~= 'table' and key ~= 'select' then
         _G[key] = val
      end
   end

   function element(tag)
      if tag == 'table' or tag == 'select' then
         return function(inner)
            return maketag(tag, inner)
         end
      else
         error('element requires input of table or select')
      end
   end
end

return require('waffle.app')