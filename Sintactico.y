%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"

int yystopparser = 0;
FILE *yyin;

int yyerror();
int yylex();
%}

/* ============================
   Tokens (del Lexer)
   ============================ */
%token CTE_INT CTE_FLOAT CTE_STR
%token ID
%token ASIG
%token SUMA MULT RESTA DIV MOD
%token PAR_IZQ PAR_DER COR_IZQ COR_DER
%token LLA_IZQ LLA_DER DOS_PUNTOS
%token IF ELSE WHILE FOR RETURN
%token INIT READ WRITE
%token INT FLOAT STRING
%token IGUAL DIST MENOR_IG MAYOR_IG
%token MENOR MAYOR
%token AND_LOG OR_LOG NOT_LOG
%token AND OR NOT
%token ISZERO CONVDATE
%token COMA PYC

%%

/* ============================
   Reglas Sintácticas
   ============================ */

programa:
    lista_sentencias
;

lista_sentencias:
    sentencia
  | lista_sentencias sentencia
;

sentencia:
    asignacion
  | seleccion
  | iteracion
  | declaracion
  | io
;

/* Asignaciones */
asignacion:
    ID ASIG expresion PYC
        { printf("Regla: Asignacion -> ID := Expresion;\n"); }
;

/* Expresiones aritméticas */
expresion:
    termino
  | expresion SUMA termino
  | expresion RESTA termino
;

termino:
    factor
  | termino MULT factor
  | termino DIV factor
  | termino MOD factor
;

factor:
    ID
  | CTE_INT
  | CTE_FLOAT
  | CTE_STR
  | PAR_IZQ expresion PAR_DER
  | CONVDATE PAR_IZQ expresion RESTA expresion RESTA expresion PAR_DER
;


/* Condiciones */
condicion:
    comparacion
  | ISZERO PAR_IZQ expresion PAR_DER
  | condicion AND comparacion
  | condicion OR comparacion
  | NOT condicion
;


comparacion:
    expresion MENOR expresion
  | expresion MAYOR expresion
  | expresion MENOR_IG expresion
  | expresion MAYOR_IG expresion
  | expresion IGUAL expresion
  | expresion DIST expresion
;

/* If / If-Else */
seleccion:
    IF PAR_IZQ condicion PAR_DER bloque
  | IF PAR_IZQ condicion PAR_DER bloque ELSE bloque
;

/* While */
iteracion:
    WHILE PAR_IZQ condicion PAR_DER bloque
;

/* Bloques de código */
bloque:
    LLA_IZQ lista_sentencias LLA_DER
;

/* Declaraciones de variables */
declaracion:
    INIT LLA_IZQ lista_declaraciones LLA_DER
;

lista_declaraciones:
    declaracion_tipo
  | lista_declaraciones declaracion_tipo
;

declaracion_tipo:
    lista_ids DOS_PUNTOS tipo PYC
;

lista_ids:
    ID
  | lista_ids COMA ID
;

tipo:
    INT
  | FLOAT
  | STRING
;

/* Entrada/Salida */
io:
    READ PAR_IZQ ID PAR_DER PYC
  | WRITE PAR_IZQ expresion PAR_DER PYC
;

%%

/* ============================
   Funciones auxiliares
   ============================ */
int main(int argc, char *argv[]) {
    if((yyin = fopen(argv[1], "rt"))==NULL) {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    } else {
        yyparse();
        fclose(yyin);
    }
    return 0;
}

int yyerror(void) {
    printf("Error Sintactico\n");
    exit(1);
}
