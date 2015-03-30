local utils = {}

utils.iterator = function(f)
   return function(...)
      local d = f(...)
      local n = 0
      return function()
         n = n + 1
         if (d and n <= #d) then return d[n]
         else return nil end
      end
   end
end

return utils