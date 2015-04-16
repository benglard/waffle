app = require('../waffle')
a = 1
b = 2
c = 3
app.repl()
app.listen()

--[[ To test repl, try this:
th> async = require 'async'
                                                                      [0.0133s]  
th> async.repl.connect({host='127.0.0.1', port=8081})
                                                                      [0.0005s]  
th> async.go()
127.0.0.1:8081> a
1  
127.0.0.1:8081> b
2  
127.0.0.1:8081> c
3  
127.0.0.1:8081> app
{
  viewFuncs : {}
  set : function: 0x0ef689e8
  abort : function: 0x0ef57520
  serve : function: 0x0ef558b0
  put : function: 0x0ef1cbb0
  properties : 
    {
      size : 10000
      get : function: 0x0ef669a8
      keys : {}
      empty : function: 0x0ef6b290
      push : function: 0x0ec0a768
      pop : function: 0x0ec0baf8
      clean : function: 0x0ef13478
      store : {}
    }
  delete : function: 0x0eef5240
  repl : function: 0x0ef57570
  post : function: 0x0ef3ea68
  error : function: 0x0ef571b0
  listen : function: 0x0ef534f0
  errorFuncs : {}
  urlCache : 
    {
      size : 20
      get : function: 0x0ef45978
      keys : {}
      empty : function: 0x0ef0a250
      push : function: 0x0ef63f00
      pop : function: 0x0ef63f68
      clean : function: 0x0ef483c0
      store : {}
    }
  get : function: 0x0ef48ab0
}
127.0.0.1:8081> _G
{
   ...
}
]]