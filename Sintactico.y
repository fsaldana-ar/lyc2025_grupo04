// Usa Lexico_ClasePractica
//Solo expresiones sin ()
%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
int yystopparser=0;
FILE  *yyin;

  int yyerror();
  int yylex();


%}

%token CTE_INT
%token ID
%token ASIG
%token SUMA
%token MULT
%token RESTA
%token DIV
%token PAR_IZQ PAR_DER COR_IZQ COR_DER
%token IF ELSE WHILE FOR RETURN INT FLOAT CHAR VOID
%token IGUAL DIST MENOR_IG MAYOR_IG
%token AND_LOG OR_LOG NOT_LOG
%token INC DEC
%token MENOR MAYOR
%token MOD COMA PYC

%%
asignacion :
	ID IGUAL CTE_INT { printf(" FIN\n"); } ;



sentencia:  	   
	asignacion {printf(" FIN\n");} ;

asignacion: 
          ID ASIG expresion {printf("    ID = Expresion es ASIGNACION\n");}
	  ;

expresion:
         termino {printf("    Termino es Expresion\n");}
	 |expresion SUMA termino {printf("    Expresion+Termino es Expresion\n");}
	 |expresion RESTA termino {printf("    Expresion-Termino es Expresion\n");}
	 ;

termino: 
       factor {printf("    Factor es Termino\n");}
       |termino MULT factor {printf("     Termino*Factor es Termino\n");}
       |termino DIV factor {printf("     Termino/Factor es Termino\n");}
       ;

factor: 
      ID {printf("    ID es Factor \n");}
      | CTE_INT {printf("    CTE_INT es Factor\n");}
	| PAR_IZQ expresion PAR_DER {printf("    Expresion entre parentesis es Factor\n");}
     	;
%%


int main(int argc, char *argv[])
{
    if((yyin = fopen(argv[1], "rt"))==NULL)
    {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
       
    }
    else
    { 
        
        yyparse();
        
    }
	fclose(yyin);
        return 0;
}
int yyerror(void)
     {
       printf("Error Sintactico\n");
	 exit (1);
     }

