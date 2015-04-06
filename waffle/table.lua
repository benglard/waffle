local table = require 'table'

table.contains = function(t, elem)
   for k, v in pairs(t) do
      if v == elem then return true end
   end
   return false
end

return table