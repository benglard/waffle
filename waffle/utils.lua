local utils = {}

utils.iterator = function(f)
   return function(...)
      local d = f(...)
      local n = 0
      local size = #d
      return function()
         n = n + 1
         if (d and n <= size) then return d[n]
         else return nil end
      end
   end
end

return utils