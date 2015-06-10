local paths = require 'paths'
local utils = require 'waffle.utils'

paths.delim = (function()
   if paths.is_win() then return '\\'
   else return '/' end
end)()

paths.add = function(p1, p2)
   if #p1 == 0 then
      return p2
   end
   if string.sub(p1, -1) == paths.delim then
      return p1 .. p2
   else
      return p1 .. paths.delim .. p2
   end
end

paths.walk = function(dir, files)
   utils.stringassert(dir)
   
   local files = files or {}
   for f in paths.files(dir) do
      if f ~= '.' and f ~= '..' then
         local ff = paths.add(dir, f)
         if paths.dirp(ff) then
            paths.walk(ff, files)
         else
            table.insert(files, ff)
         end
      end
   end
   return files
end

paths.gwalk = utils.iterator(paths.walk)

return paths