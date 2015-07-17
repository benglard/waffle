local base = extends 'examples/baseluatemp.lua'
return block(base, 'content'){
   h3 'Welcome, ${name}',
   p 'Time: ${time}',
   ul(each([[${users}]], li)),
   element 'table' {
      thead {
         tr {
            th 'One',
            th 'Two',
            th 'Three'
         }
      },
      tbody {
         tr {
            td '1',
            td '2',
            td '3'
         },
         tr {
            td '4',
            td '5',
            td '6'
         }
      }
   },
   br, br,
   img {
      src = 'https://www.google.com/images/srpr/logo11w.png'
   }
}