 function verifica(numero: integer): integer = {
     var res: integer;

     if (numero > 0) {
         res = 1;
     }
     else {
         if (numero < 0) {
             res = -1;
         }
         else {
             res = 0;
         }
     }
     return res;
 }

     var numero: integer;
     var x: integer;


     console.log("Digite um número");

     readline(numero);

     x = verifica(numero);

     console.log(x);

